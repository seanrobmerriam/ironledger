-module(prop_payments).

-include_lib("proper/include/proper.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-export([
    prop_transfer_preserves_total_balance_and_balances_entries/0,
    prop_transfer_is_idempotent/0
]).

-spec prop_transfer_preserves_total_balance_and_balances_entries() -> term().
prop_transfer_preserves_total_balance_and_balances_entries() ->
    ?SETUP(fun setup_mnesia/0,
        ?FORALL({SourceBalance, TransferAmount, Currency}, transfer_case(),
            begin
                ok = reset_tables(),
                {SourceId, DestId} = create_accounts(Currency),
                ok = seed_balance(SourceId, Currency, SourceBalance),
                TotalBefore = total_balance(SourceId, DestId),
                {ok, Txn} = cb_payments:transfer(
                    unique_id(<<"transfer-">>),
                    SourceId,
                    DestId,
                    TransferAmount,
                    Currency,
                    <<"PropEr transfer">>
                ),
                TotalAfter = total_balance(SourceId, DestId),
                {ok, Entries} = cb_ledger:get_entries_for_transaction(Txn#transaction.txn_id),
                DebitTotal = sum_entries(debit, Entries),
                CreditTotal = sum_entries(credit, Entries),
                TotalBefore =:= TotalAfter andalso
                length(Entries) =:= 2 andalso
                DebitTotal =:= CreditTotal andalso
                DebitTotal =:= TransferAmount andalso
                lists:all(fun(Entry) -> is_integer(Entry#ledger_entry.amount) end, Entries)
            end
        )
    ).

-spec prop_transfer_is_idempotent() -> term().
prop_transfer_is_idempotent() ->
    ?SETUP(fun setup_mnesia/0,
        ?FORALL({SourceBalance, TransferAmount, Currency}, transfer_case(),
            begin
                ok = reset_tables(),
                {SourceId, DestId} = create_accounts(Currency),
                ok = seed_balance(SourceId, Currency, SourceBalance),
                IdempotencyKey = unique_id(<<"idempotency-">>),
                {ok, FirstTxn} = cb_payments:transfer(
                    IdempotencyKey,
                    SourceId,
                    DestId,
                    TransferAmount,
                    Currency,
                    <<"Idempotent transfer">>
                ),
                BalanceAfterFirst = total_balance(SourceId, DestId),
                {ok, SecondTxn} = cb_payments:transfer(
                    IdempotencyKey,
                    SourceId,
                    DestId,
                    TransferAmount,
                    Currency,
                    <<"Idempotent transfer">>
                ),
                BalanceAfterSecond = total_balance(SourceId, DestId),
                {ok, Entries} = cb_ledger:get_entries_for_transaction(FirstTxn#transaction.txn_id),
                FirstTxn#transaction.txn_id =:= SecondTxn#transaction.txn_id andalso
                BalanceAfterFirst =:= BalanceAfterSecond andalso
                length(Entries) =:= 2
            end
        )
    ).

transfer_case() ->
    ?LET({TransferAmount, ExtraBalance, Currency},
        {range(1, 100000), range(0, 100000), valid_currency()},
        {TransferAmount + ExtraBalance, TransferAmount, Currency}).

valid_currency() ->
    elements(['USD', 'EUR', 'GBP', 'JPY']).

setup_mnesia() ->
    ok = ensure_mnesia_started(),
    cb_schema:create_tables(),
    fun() ->
        mnesia:stop(),
        mnesia:delete_schema([node()]),
        ok
    end.

ensure_mnesia_started() ->
    case mnesia:start() of
        ok ->
            ok;
        {error, {already_started, _}} ->
            ok
    end.

reset_tables() ->
    Tables = [party, account, transaction, ledger_entry],
    lists:foreach(
        fun(Table) ->
            {atomic, ok} = mnesia:clear_table(Table)
        end,
        Tables
    ),
    ok.

create_accounts(Currency) ->
    {ok, Party} = cb_party:create_party(<<"PropEr Customer">>, unique_email()),
    {ok, Source} = cb_accounts:create_account(Party#party.party_id, <<"Source Account">>, Currency),
    {ok, Dest} = cb_accounts:create_account(Party#party.party_id, <<"Destination Account">>, Currency),
    {Source#account.account_id, Dest#account.account_id}.

seed_balance(_AccountId, _Currency, 0) ->
    ok;
seed_balance(AccountId, Currency, Amount) ->
    {ok, _Txn} = cb_payments:deposit(
        unique_id(<<"seed-">>),
        AccountId,
        Amount,
        Currency,
        <<"Seed balance">>
    ),
    ok.

total_balance(SourceId, DestId) ->
    {ok, Source} = cb_accounts:get_account(SourceId),
    {ok, Dest} = cb_accounts:get_account(DestId),
    Source#account.balance + Dest#account.balance.

sum_entries(EntryType, Entries) ->
    lists:sum([
        Entry#ledger_entry.amount
     || Entry <- Entries,
        Entry#ledger_entry.entry_type =:= EntryType
    ]).

unique_id(Prefix) ->
    <<Prefix/binary, (uuid:uuid_to_string(uuid:get_v4(), binary_standard))/binary>>.

unique_email() ->
    <<(unique_id(<<"proper-">>))/binary, "@example.com">>.
