-record(savings_product, {
    product_id          :: binary(),
    name                :: binary(),
    description         :: binary(),
    currency            :: atom(),
    interest_rate       :: float(),
    interest_type       :: atom(),
    compounding_period :: atom(),
    minimum_balance     :: integer(),
    status              :: atom(),
    created_at          :: integer(),
    updated_at          :: integer()
}).

-define(VALID_CURRENCIES, ['USD', 'EUR', 'GBP', 'JPY', 'CHF']).
-define(VALID_INTEREST_TYPES, [simple, compound]).
-define(VALID_COMPOUNDING_PERIODS, [daily, monthly, quarterly, annually]).
