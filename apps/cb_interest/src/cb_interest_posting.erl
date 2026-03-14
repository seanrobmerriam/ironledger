-module(cb_interest_posting).

-include("cb_interest.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-export([
    post_accrued_interest/2,
    process_daily_accruals/0,
    get_interest_expense_account_id/0,
    get_interest_income_account_id/0
]).

-define(INTEREST_EXPENSE_ACCOUNT_ID, <<"interest-expense">>).
-define(INTEREST_INCOME_ACCOUNT_ID, <<"interest-income">>).
-define(INTEREST_TXN_TYPE, interest_posting).

-spec post_accrued_interest(uuid(), amount()) -> {ok, uuid()} | {error, atom()}.
post_accrued_interest(AccountId, Amount) when is_binary(AccountId), is_integer(Amount), Amount > 0 ->
    F = fun() ->
        case mnesia:read(account, AccountId) of
            [] ->
                {error, account_not_found};
            [Account] ->
                case Account#account.status of
                    closed ->
                        {error, account_closed};
                    _ ->
                        TxnId = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
                        Now = erlang:system_time(millisecond),
                        CreditEntry = #ledger_entry{
                            entry_id = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
                            txn_id = TxnId,
                            account_id = AccountId,
                            entry_type = credit,
                            amount = Amount,
                            currency = Account#account.currency,
                            description = <<"Interest posting">>,
                            posted_at = Now
                        },
                        DebitEntry = #ledger_entry{
                            entry_id = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
                            txn_id = TxnId,
                            account_id = get_interest_expense_account_id(),
                            entry_type = debit,
                            amount = Amount,
                            currency = Account#account.currency,
                            description = <<"Interest expense">>,
                            posted_at = Now
                        },
                        ok = cb_ledger:post_entries(DebitEntry, CreditEntry),
                        {ok, TxnId}
                end
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end.

-spec process_daily_accruals() -> {ok, non_neg_integer()}.
process_daily_accruals() ->
    Accruals = cb_interest_accrual:get_active_accruals(),
    process_accruals(Accruals, 0).

-spec get_interest_expense_account_id() -> <<_:128>>.
get_interest_expense_account_id() ->
    ?INTEREST_EXPENSE_ACCOUNT_ID.

-spec get_interest_income_account_id() -> <<_:120>>.
get_interest_income_account_id() ->
    ?INTEREST_INCOME_ACCOUNT_ID.

-spec process_accruals([interest_accrual()], non_neg_integer()) -> {ok, non_neg_integer()}.
process_accruals([], Count) ->
    {ok, Count};
process_accruals([Accrual | Rest], Count) ->
    AccountId = Accrual#interest_accrual.account_id,
    case cb_accounts:get_balance(AccountId) of
        {ok, #{balance := CurrentBalance}} ->
            case calculate_and_post_daily_interest(Accrual, CurrentBalance) of
                {ok, _TxnId} ->
                    process_accruals(Rest, Count + 1);
                {error, _} ->
                    process_accruals(Rest, Count)
            end;
        {error, _} ->
            process_accruals(Rest, Count)
    end.

-spec calculate_and_post_daily_interest(interest_accrual(), amount()) -> {ok, uuid()} | {error, atom()}.
calculate_and_post_daily_interest(Accrual, CurrentBalance) ->
    DailyRate = Accrual#interest_accrual.daily_rate,
    DailyInterest = cb_interest:calculate_interest(CurrentBalance, DailyRate, 1),
    if
        DailyInterest > 0 ->
            post_accrued_interest(Accrual#interest_accrual.account_id, DailyInterest);
        true ->
            {ok, <<"no-interest">>}
    end.
