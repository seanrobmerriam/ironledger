%% @doc Mnesia Database Schema Management
%%
%% This module is responsible for creating and managing the Mnesia database schema
%% and tables for the IronLedger core banking system.
%%
%% <h2>What is Mnesia?</h2>
%%
%% Mnesia is a distributed, soft real-time database management system (DBMS) bundled
%% with Erlang/OTP. It provides:
%%
%% <ul>
%%   <li>ACID transactions (atomic, consistent, isolated, durable)</li>
%%   <li>Schema flexibility - can be modified at runtime</li>
%%   <li>Replication - tables can be replicated across nodes</li>
%%   <li>In-memory and disk storage options</li>
%% </ul>
%%
%% <h2>Table Configuration</h2>
%%
%% All tables in IronLedger use `ram_copies' (in-memory only) for the prototype.
%% This provides fast read/write performance but data is lost on node restart.
%% For production, consider:
%%
%% <ul>
%%   <li>`disc_copies' - Persist to disk, survive node restarts</li>
%%   <li>`disc_only_copies' - Disk-only for large datasets</li>
%%   <li>Table replication across multiple nodes for HA</li>
%% </ul>
%%
%% <h2>Table Indexes</h2>
%%
%% Each table has secondary indexes defined to speed up common query patterns:
%% <ul>
%%   <li>party: email, status</li>
%%   <li>account: party_id, status</li>
%%   <li>transaction: idempotency_key, source_account_id, dest_account_id, status</li>
%%   <li>ledger_entry: txn_id, account_id</li>
%% </ul>
%%
%% @see mnesia
-module(cb_schema).

-include_lib("cb_ledger/include/cb_ledger.hrl").

-export([create_tables/0]).

%% @doc Create all Mnesia tables if they don't exist.
%%
%% This function creates the following tables:
%% <ul>
%%   <li>`party' - Customer/party records</li>
%%   <li>`account' - Bank accounts</li>
%%   <li>`transaction' - Financial transactions</li>
%%   <li>`ledger_entry' - Double-entry ledger entries</li>
%% </ul>
%%
%% Each table is created with the specification defined in table_spec/1.
%% If a table already exists, the function returns successfully (idempotent).
%%
%% @returns `ok' on success (always succeeds if Mnesia is running)
-spec create_tables() -> ok.
create_tables() ->
    Tables = [party, account, transaction, ledger_entry],
    lists:foreach(fun create_if_not_exists/1, Tables),
    ok.

%% @private Create a single table if it doesn't exist.
%%
%% Attempts to create a table with the specified name and attributes.
%% If the table already exists, this is treated as a successful operation.
%% Any other error is propagated as a runtime error.
%%
%% @param TableName The name of the table to create
%% @returns `ok' on success
-spec create_if_not_exists(party | account | transaction | ledger_entry) -> ok.
create_if_not_exists(TableName) ->
    case mnesia:create_table(TableName, table_spec(TableName)) of
        {atomic, ok} ->
            ok;
        {aborted, {already_exists, _Table}} ->
            ok;
        {aborted, Reason} ->
            error({schema_error, TableName, Reason})
    end.

%% @private Table specifications from docs/data-schema.md.
%%
%% Returns the Mnesia table specification for each table type, including:
%% <ul>
%%   <li>Storage type (ram_copies)</li>
%%   <li>Record attributes (from record_info)</li>
%%   <li>Secondary indexes for common query patterns</li>
%% </ul>
%%
%% @param TableName The table to get spec for
%% @returns Mnesia table specification proplist
-spec table_spec(party | account | transaction | ledger_entry) ->
    [{'attributes',[atom(),...]} |
     {'index',['account_id' | 'dest_account_id' | 'email' | 'idempotency_key' |
               'party_id' | 'source_account_id' | 'status' | 'txn_id',...]} |
     {'ram_copies',[atom(),...]},...].
table_spec(party) ->
    [
        {ram_copies, [node()]},
        {attributes, record_info(fields, party)},
        {index, [email, status]}
    ];
table_spec(account) ->
    [
        {ram_copies, [node()]},
        {attributes, record_info(fields, account)},
        {index, [party_id, status]}
    ];
table_spec(transaction) ->
    [
        {ram_copies, [node()]},
        {attributes, record_info(fields, transaction)},
        {index, [idempotency_key, source_account_id, dest_account_id, status]}
    ];
table_spec(ledger_entry) ->
    [
        {ram_copies, [node()]},
        {attributes, record_info(fields, ledger_entry)},
        {index, [txn_id, account_id]}
    ].
