-module(cb_savings_products).

-include("savings_product.hrl").

-export([
    create_product/7,
    get_product/1,
    list_products/0,
    activate_product/1,
    deactivate_product/1
]).

-type product_id() :: binary().

-spec create_product(
    binary(),
    binary(),
    atom(),
    float(),
    atom(),
    atom(),
    integer()
) -> {ok, #savings_product{}} | {error, atom()}.
create_product(Name, Description, Currency, InterestRate, InterestType, CompoundingPeriod, MinimumBalance) 
        when is_binary(Name), is_binary(Description), is_integer(MinimumBalance), MinimumBalance >= 0 ->
    case lists:member(Currency, ?VALID_CURRENCIES) of
        true ->
            case lists:member(InterestType, ?VALID_INTEREST_TYPES) of
                true ->
                    case lists:member(CompoundingPeriod, ?VALID_COMPOUNDING_PERIODS) of
                        true ->
                            F = fun() ->
                                Now = erlang:system_time(millisecond),
                                ProductId = uuid:uuid_to_string(uuid:get_v4(), binary_standard),
                                Product = #savings_product{
                                    product_id = ProductId,
                                    name = Name,
                                    description = Description,
                                    currency = Currency,
                                    interest_rate = InterestRate,
                                    interest_type = InterestType,
                                    compounding_period = CompoundingPeriod,
                                    minimum_balance = MinimumBalance,
                                    status = active,
                                    created_at = Now,
                                    updated_at = Now
                                },
                                mnesia:write(Product),
                                {ok, Product}
                            end,
                            case mnesia:transaction(F) of
                                {atomic, Result} -> Result;
                                {aborted, _Reason} -> {error, database_error}
                            end;
                        false ->
                            {error, invalid_compounding_period}
                    end;
                false ->
                    {error, invalid_interest_type}
            end;
        false ->
            {error, unsupported_currency}
    end;
create_product(_, _, _, _, _, _, _) ->
    {error, invalid_parameters}.

-spec get_product(product_id()) -> {ok, #savings_product{}} | {error, atom()}.
get_product(ProductId) when is_binary(ProductId) ->
    F = fun() ->
        case mnesia:read(savings_product, ProductId) of
            [Product] -> {ok, Product};
            [] -> {error, product_not_found}
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end;
get_product(_) ->
    {error, invalid_product_id}.

-spec list_products() -> {ok, [#savings_product{}]} | {error, atom()}.
list_products() ->
    F = fun() ->
        AllProducts = mnesia:select(savings_product, [{'_', [], ['$_']}]),
        Sorted = lists:sort(
            fun(A, B) -> A#savings_product.created_at >= B#savings_product.created_at end,
            AllProducts
        ),
        Sorted
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> {ok, Result};
        {aborted, _Reason} -> {error, database_error}
    end.

-spec activate_product(product_id()) -> {ok, #savings_product{}} | {error, atom()}.
activate_product(ProductId) when is_binary(ProductId) ->
    F = fun() ->
        case mnesia:read(savings_product, ProductId, write) of
            [Product] ->
                case Product#savings_product.status of
                    inactive ->
                        Now = erlang:system_time(millisecond),
                        Updated = Product#savings_product{status = active, updated_at = Now},
                        mnesia:write(Updated),
                        {ok, Updated};
                    active ->
                        {error, product_already_active}
                end;
            [] ->
                {error, product_not_found}
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end;
activate_product(_) ->
    {error, invalid_product_id}.

-spec deactivate_product(product_id()) -> {ok, #savings_product{}} | {error, atom()}.
deactivate_product(ProductId) when is_binary(ProductId) ->
    F = fun() ->
        case mnesia:read(savings_product, ProductId, write) of
            [Product] ->
                case Product#savings_product.status of
                    active ->
                        Now = erlang:system_time(millisecond),
                        Updated = Product#savings_product{status = inactive, updated_at = Now},
                        mnesia:write(Updated),
                        {ok, Updated};
                    inactive ->
                        {error, product_already_inactive}
                end;
            [] ->
                {error, product_not_found}
        end
    end,
    case mnesia:transaction(F) of
        {atomic, Result} -> Result;
        {aborted, _Reason} -> {error, database_error}
    end;
deactivate_product(_) ->
    {error, invalid_product_id}.
