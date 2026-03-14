-module(cb_interest_accrual).

-include("cb_interest.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-export([
    start_accrual/4,
    calculate_daily_accrual/2,
    get_accrual/1,
    close_accrual/1,
    get_active_accruals/0,
    get_accruals_for_account/1
]).

-define(ACCRUAL_TABLE, interest_accrual).

-spec start_accrual(uuid(), uuid(), amount(), interest_rate()) -> {ok, interest_accrual()} | {error, atom()}.
start_accrual(AccountId, ProductId, Balance, AnnualRate) when is_binary(AccountId), is_binary(ProductId), is_integer(Balance), Balance >= 0, is_float(AnnualRate), AnnualRate >= 0 ->
    F = fun() ->
        case mnesia:read(account, AccountId) of
            [] ->
                {error, account_not_found};
            [Account] ->
                case Account#account.status of
                    closed ->
                        {error, account_closed};
                    _ ->
                        DailyRate = cb_interest:calculate_daily_rate(AnnualRate),
                        Now = erlang:system_time(millisecond),
                        AccrualId = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
                        Accrual = #interest_accrual{
                            accrual_id = AccrualId,
                            account_id = AccountId,
                            product_id = ProductId,
                            interest_rate = AnnualRate,
                            daily_rate = DailyRate,
                            start_date = Now,
                            end_date = undefined,
                            balance = Balance,
                            accrued_amount = 0,
                            status = accruing,
                            created_at = Now
                        },
                        mnesia:write(Accrual),
                        {ok, Accrual}
                end
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end.

-spec calculate_daily_accrual(uuid(), amount()) -> amount().
calculate_daily_accrual(AccountId, Balance) when is_binary(AccountId), is_integer(Balance), Balance >= 0 ->
    F = fun() ->
        case mnesia:read(?ACCRUAL_TABLE, AccountId) of
            [] ->
                0;
            [Accrual] ->
                case Accrual#interest_accrual.status of
                    accruing ->
                        DailyRate = Accrual#interest_accrual.daily_rate,
                        Interest = cb_interest:calculate_interest(Balance, DailyRate, 1),
                        Accrual#interest_accrual.balance + Interest;
                    _ ->
                        0
                end
        end
    end,
    {atomic, Result} = mnesia:transaction(F),
    Result.

-spec get_accrual(uuid()) -> {ok, interest_accrual()} | {error, atom()}.
get_accrual(AccrualId) ->
    F = fun() ->
        case mnesia:read(?ACCRUAL_TABLE, AccrualId) of
            [Accrual] -> {ok, Accrual};
            [] -> {error, accrual_not_found}
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end.

-spec close_accrual(uuid()) -> {ok, interest_accrual()} | {error, atom()}.
close_accrual(AccrualId) ->
    F = fun() ->
        case mnesia:read(?ACCRUAL_TABLE, AccrualId, write) of
            [] ->
                {error, accrual_not_found};
            [Accrual] ->
                Now = erlang:system_time(millisecond),
                Updated = Accrual#interest_accrual{
                    end_date = Now,
                    status = closed
                },
                mnesia:write(Updated),
                {ok, Updated}
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end.

-spec get_active_accruals() -> [interest_accrual()].
get_active_accruals() ->
    F = fun() ->
        MatchHead = #interest_accrual{status = accruing, _ = '_'},
        mnesia:select(?ACCRUAL_TABLE, [{MatchHead, [], ['$_']}])
    end,
    {atomic, Accruals} = mnesia:transaction(F),
    Accruals.

-spec get_accruals_for_account(binary()) -> [interest_accrual()].
get_accruals_for_account(AccountId) ->
    F = fun() ->
        mnesia:index_read(?ACCRUAL_TABLE, AccountId, account_id)
    end,
    {atomic, Accruals} = mnesia:transaction(F),
    Accruals.
