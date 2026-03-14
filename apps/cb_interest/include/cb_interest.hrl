-ifndef(CB_INTEREST_HRL).
-define(CB_INTEREST_HRL, true).

-type interest_type() :: simple | compound.
-type compounding_period() :: daily | monthly | quarterly | annually.

-type interest_rate() :: float().

-type accrual_status() :: accruing | posted | closed.

-record(interest_accrual, {
    accrual_id     :: binary(),
    account_id     :: binary(),
    product_id     :: binary(),
    interest_rate  :: interest_rate(),
    daily_rate     :: interest_rate(),
    start_date     :: non_neg_integer(),
    end_date       :: non_neg_integer() | undefined,
    balance        :: non_neg_integer(),
    accrued_amount :: non_neg_integer(),
    status         :: accrual_status(),
    created_at     :: non_neg_integer()
}).

-type interest_accrual() :: #interest_accrual{}.

-type interest_product() :: #{
    product_id => binary(),
    interest_type => interest_type(),
    compounding_period => compounding_period(),
    annual_rate => interest_rate()
}.

-export_type([
    interest_type/0,
    compounding_period/0,
    interest_rate/0,
    accrual_status/0,
    interest_accrual/0,
    interest_product/0
]).

-endif.
