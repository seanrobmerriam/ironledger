-module(cb_loan_products).
-behaviour(gen_server).

-export([
         start_link/0,
         create_product/9,
         get_product/1,
         list_products/0,
         update_product/2,
         deactivate_product/1
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("loan.hrl").
-include_lib("cb_ledger/include/cb_ledger.hrl").

-define(SERVER, ?MODULE).
-define(TABLE, loan_products).

-record(state, {}).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

-spec create_product(binary(), binary(), atom(), integer(), integer(), integer(), integer(), float(), atom()) ->
    {ok, product_id()} | {error, term()}.
create_product(Name, Description, Currency, MinAmount, MaxAmount, MinTermMonths, MaxTermMonths, InterestRate, InterestType) ->
    gen_server:call(?SERVER, {create_product, Name, Description, Currency, MinAmount, MaxAmount, MinTermMonths, MaxTermMonths, InterestRate, InterestType}).

-spec get_product(product_id()) -> {ok, loan_product()} | {error, not_found}.
get_product(ProductId) ->
    gen_server:call(?SERVER, {get_product, ProductId}).

-spec list_products() -> [loan_product()].
list_products() ->
    gen_server:call(?SERVER, list_products).

-spec update_product(product_id(), map()) -> {ok, loan_product()} | {error, term()}.
update_product(ProductId, Updates) ->
    gen_server:call(?SERVER, {update_product, ProductId, Updates}).

-spec deactivate_product(product_id()) -> {ok, loan_product()} | {error, term()}.
deactivate_product(ProductId) ->
    gen_server:call(?SERVER, {deactivate_product, ProductId}).

init([]) ->
    case mnesia:create_table(?TABLE, [
        {attributes, record_info(fields, loan_product)},
        {type, set},
        {ram_copies, [node()]}
    ]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, _}} -> ok;
        {aborted, Reason} -> error(Reason)
    end,
    {ok, #state{}}.

handle_call({create_product, Name, Description, Currency, MinAmount, MaxAmount, MinTermMonths, MaxTermMonths, InterestRate, InterestType}, _From, State) ->
    Reply = do_create_product(Name, Description, Currency, MinAmount, MaxAmount, MinTermMonths, MaxTermMonths, InterestRate, InterestType),
    {reply, Reply, State};

handle_call({get_product, ProductId}, _From, State) ->
    Reply = do_get_product(ProductId),
    {reply, Reply, State};

handle_call(list_products, _From, State) ->
    Reply = do_list_products(),
    {reply, Reply, State};

handle_call({update_product, ProductId, Updates}, _From, State) ->
    Reply = do_update_product(ProductId, Updates),
    {reply, Reply, State};

handle_call({deactivate_product, ProductId}, _From, State) ->
    Reply = do_deactivate_product(ProductId),
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

do_create_product(Name, Description, Currency, MinAmount, MaxAmount, MinTermMonths, MaxTermMonths, InterestRate, InterestType) ->
    ValidCurrency = validate_currency(Currency),
    ValidInterestType = validate_interest_type(InterestType),
    case {ValidCurrency, ValidInterestType} of
        {ok, ok} ->
            ProductId = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
            Now = erlang:system_time(millisecond),
            Product = #loan_product{
                product_id = ProductId,
                name = Name,
                description = Description,
                currency = Currency,
                min_amount = MinAmount,
                max_amount = MaxAmount,
                min_term_months = MinTermMonths,
                max_term_months = MaxTermMonths,
                interest_rate = InterestRate,
                interest_type = InterestType,
                status = active,
                created_at = Now,
                updated_at = Now
            },
            Fun = fun() -> mnesia:write(Product) end,
            case mnesia:transaction(Fun) of
                {atomic, _} -> {ok, ProductId};
                {aborted, Reason} -> {error, Reason}
            end;
        {error, _} = Error ->
            Error
    end.

do_get_product(ProductId) ->
    Fun = fun() -> mnesia:read({?TABLE, ProductId}) end,
    case mnesia:transaction(Fun) of
        {atomic, [Product]} -> {ok, Product};
        {atomic, []} -> {error, not_found}
    end.

do_list_products() ->
    Fun = fun() -> mnesia:select(?TABLE, [{#loan_product{status = '$1', _ = '_'}, [{'==', '$1', active}], ['$_']}]) end,
    case mnesia:transaction(Fun) of
        {atomic, Products} -> Products
    end.

do_update_product(ProductId, Updates) ->
    Fun = fun() ->
        case mnesia:read({?TABLE, ProductId}) of
            [Product] ->
                UpdatedProduct = apply_updates(Product, Updates),
                mnesia:write(UpdatedProduct),
                {ok, UpdatedProduct};
            [] ->
                {error, not_found}
        end
    end,
    case mnesia:transaction(Fun) of
        {atomic, Result} -> Result;
        {aborted, Reason} -> {error, Reason}
    end.

do_deactivate_product(ProductId) ->
    do_update_product(ProductId, #{status => inactive}).

apply_updates(Product, Updates) ->
    Now = erlang:system_time(millisecond),
    maps:fold(fun(K, V, Acc) ->
        case K of
            name -> Acc#loan_product{name = V, updated_at = Now};
            description -> Acc#loan_product{description = V, updated_at = Now};
            currency -> Acc#loan_product{currency = V, updated_at = Now};
            min_amount -> Acc#loan_product{min_amount = V, updated_at = Now};
            max_amount -> Acc#loan_product{max_amount = V, updated_at = Now};
            interest_rate -> Acc#loan_product{interest_rate = V, updated_at = Now};
            interest_type -> Acc#loan_product{interest_type = V, updated_at = Now};
            status -> Acc#loan_product{status = V, updated_at = Now};
            _ -> Acc
        end
    end, Product, Updates).

validate_currency(Currency) ->
    ValidCurrencies = ['USD', 'EUR', 'GBP', 'JPY'],
    case lists:member(Currency, ValidCurrencies) of
        true -> ok;
        false -> {error, unsupported_currency}
    end.

validate_interest_type(InterestType) ->
    ValidTypes = [flat, declining],
    case lists:member(InterestType, ValidTypes) of
        true -> ok;
        false -> {error, invalid_interest_type}
    end.
