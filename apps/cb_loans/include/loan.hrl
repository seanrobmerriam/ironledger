-record(loan_product, {
    product_id :: binary(),
    name :: binary(),
    description :: binary(),
    currency :: atom(),
    min_amount :: integer(),
    max_amount :: integer(),
    min_term_months :: integer(),
    max_term_months :: integer(),
    interest_rate :: float(),
    interest_type :: atom(),
    status :: atom(),
    created_at :: integer(),
    updated_at :: integer()
}).

-record(loan_account, {
    loan_id :: binary(),
    product_id :: binary(),
    party_id :: binary(),
    account_id :: binary(),
    principal :: integer(),
    currency :: atom(),
    interest_rate :: float(),
    term_months :: integer(),
    monthly_payment :: integer(),
    outstanding_balance :: integer(),
    status :: atom(),
    disbursed_at :: integer(),
    created_at :: integer(),
    updated_at :: integer()
}).

-record(loan_repayment, {
    repayment_id :: binary(),
    loan_id :: binary(),
    amount :: integer(),
    principal_portion :: integer(),
    interest_portion :: integer(),
    penalty :: integer(),
    due_date :: integer(),
    paid_at :: integer(),
    status :: atom(),
    created_at :: integer()
}).

-type loan_product() :: #loan_product{}.
-type loan_account() :: #loan_account{}.
-type loan_repayment() :: #loan_repayment{}.
-type loan_id() :: binary().
-type product_id() :: binary().
-type repayment_id() :: binary().    
