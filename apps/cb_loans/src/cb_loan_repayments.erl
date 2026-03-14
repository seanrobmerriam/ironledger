-module(cb_loan_repayments).
-behaviour(gen_server).

-export([
         start_link/0,
         record_repayment/4,
         get_repayments/1,
         calculate_overdue/1,
         get_repayment/1,
         update_repayment_status/2
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("loan.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-define(SERVER, ?MODULE).
-define(TABLE, loan_repayments).

-record(state, {}).

-define(GRACE_PERIOD_DAYS, 5).
-define(LATE_PENALTY_BPS, 500).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

-spec record_repayment(loan_id(), amount(), integer(), amount()) ->
    {ok, repayment_id()} | {error, term()}.
record_repayment(LoanId, Amount, DueDate, PrincipalPortion) ->
    gen_server:call(?SERVER, {record_repayment, LoanId, Amount, DueDate, PrincipalPortion}).

-spec get_repayments(loan_id()) -> [loan_repayment()].
get_repayments(LoanId) ->
    gen_server:call(?SERVER, {get_repayments, LoanId}).

-spec calculate_overdue(loan_id()) -> {ok, amount()} | {error, term()}.
calculate_overdue(LoanId) ->
    gen_server:call(?SERVER, {calculate_overdue, LoanId}).

-spec get_repayment(repayment_id()) -> {ok, loan_repayment()} | {error, not_found}.
get_repayment(RepaymentId) ->
    gen_server:call(?SERVER, {get_repayment, RepaymentId}).

-spec update_repayment_status(repayment_id(), atom()) -> {ok, loan_repayment()} | {error, term()}.
update_repayment_status(RepaymentId, Status) ->
    gen_server:call(?SERVER, {update_repayment_status, RepaymentId, Status}).

init([]) ->
    case mnesia:create_table(?TABLE, [
        {attributes, record_info(fields, loan_repayment)},
        {type, set},
        {ram_copies, [node()]}
    ]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, _}} -> ok;
        {aborted, Reason} -> error(Reason)
    end,
    {ok, #state{}}.

handle_call({record_repayment, LoanId, Amount, DueDate, PrincipalPortion}, _From, State) ->
    Reply = do_record_repayment(LoanId, Amount, DueDate, PrincipalPortion),
    {reply, Reply, State};

handle_call({get_repayments, LoanId}, _From, State) ->
    Reply = do_get_repayments(LoanId),
    {reply, Reply, State};

handle_call({calculate_overdue, LoanId}, _From, State) ->
    Reply = do_calculate_overdue(LoanId),
    {reply, Reply, State};

handle_call({get_repayment, RepaymentId}, _From, State) ->
    Reply = do_get_repayment(RepaymentId),
    {reply, Reply, State};

handle_call({update_repayment_status, RepaymentId, Status}, _From, State) ->
    Reply = do_update_repayment_status(RepaymentId, Status),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, unknown_call, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

do_record_repayment(LoanId, Amount, DueDate, PrincipalPortion) ->
    case cb_loan_accounts:get_loan(LoanId) of
        {ok, Loan} ->
            InterestPortion = Amount - PrincipalPortion,
            Penalty = calculate_penalty(Loan, DueDate),
            RepaymentId = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
            Now = erlang:system_time(millisecond),
            Repayment = #loan_repayment{
                repayment_id = RepaymentId,
                loan_id = LoanId,
                amount = Amount,
                principal_portion = PrincipalPortion,
                interest_portion = InterestPortion,
                penalty = Penalty,
                due_date = DueDate,
                paid_at = Now,
                status = pending,
                created_at = Now
            },
            Fun = fun() -> mnesia:write(Repayment) end,
            case mnesia:transaction(Fun) of
                {atomic, _} -> {ok, RepaymentId};
                {aborted, Reason} -> {error, Reason}
            end;
        {error, _} = Error ->
            Error
    end.

do_get_repayments(LoanId) ->
    Fun = fun() -> mnesia:select(?TABLE, [{#loan_repayment{loan_id = '$1', _ = '_'}, [{'==', '$1', LoanId}], ['$_']}]) end,
    case mnesia:transaction(Fun) of
        {atomic, Repayments} -> Repayments;
        {aborted, _} -> []
    end.

do_calculate_overdue(LoanId) ->
    case do_get_repayments(LoanId) of
        [] ->
            {ok, 0};
        Repayments ->
            Now = erlang:system_time(millisecond),
            GracePeriodMs = ?GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000,
            Overdue = lists:foldl(fun(Repayment, Acc) ->
                case Repayment#loan_repayment.status of
                    pending ->
                        DueDate = Repayment#loan_repayment.due_date,
                        if Now > (DueDate + GracePeriodMs) ->
                            Acc + Repayment#loan_repayment.amount + Repayment#loan_repayment.penalty;
                        true ->
                            Acc
                        end;
                    _ ->
                        Acc
                end
            end, 0, Repayments),
            {ok, Overdue}
    end.

do_get_repayment(RepaymentId) ->
    Fun = fun() -> mnesia:read({?TABLE, RepaymentId}) end,
    case mnesia:transaction(Fun) of
        {atomic, [Repayment]} -> {ok, Repayment};
        {atomic, []} -> {error, not_found}
    end.

do_update_repayment_status(RepaymentId, Status) ->
    ValidStatuses = [pending, paid, late, defaulted],
    case lists:member(Status, ValidStatuses) of
        true ->
            Fun = fun() ->
                case mnesia:read({?TABLE, RepaymentId}) of
                    [Repayment] ->
                        Updated = Repayment#loan_repayment{
                            status = Status,
                            paid_at = erlang:system_time(millisecond)
                        },
                        mnesia:write(Updated),
                        {ok, Updated};
                    [] ->
                        {error, not_found}
                end
            end,
            case mnesia:transaction(Fun) of
                {atomic, Result} -> Result;
                {aborted, Reason} -> {error, Reason}
            end;
        false ->
            {error, invalid_status}
    end.

calculate_penalty(_Loan, _DueDate) ->
    0.
