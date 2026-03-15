# cb_interest

Interest calculation - simple and compound interest, daily accruals, and interest posting.

## Module Overview

The cb_interest module handles interest calculations for both savings and loan accounts. It supports simple interest, compound interest, daily accruals, and automatic interest posting to accounts.

## Key Concepts

### Daily Accruals

Interest accrues daily based on the account balance. The daily rate = annual_rate / 365 (or 360 for some conventions).

### Interest Posting

Accrued interest can be posted to accounts periodically (monthly, quarterly) or on demand.

### Interest Types

- `simple` - Interest calculated only on principal
- `compound` - Interest calculated on principal + accrued interest

## Types

### interest_calculation()
Map containing principal, rate, days, and calculation type.

### accrual_record()
Record of accrued interest for an account.

## Functions

### calculate_simple_interest(Principal, AnnualRate, Days)

Calculates simple interest: I = P × r × t where P is principal, r is annual rate, t is time in years.

**Parameters:**
- `Principal` - Principal amount in minor units
- `AnnualRate` - Annual interest rate (e.g., 0.05 for 5%)
- `Days` - Number of days

**Returns:** `{ok, amount()}` - Interest amount in minor units

### calculate_compound_interest(Principal, AnnualRate, Days, CompoundingPeriodsPerYear)

Calculates compound interest using the formula: A = P(1 + r/n)^(nt) where n is compounding periods per year.

**Returns:** `{ok, amount()}` - Total amount including interest

### accrue_interest(AccountId, AnnualRate, StartDate, EndDate)

Accrues interest for an account over a date range. Creates accrual entries in the ledger without actually posting the interest.

**Returns:** `{ok, amount()} | {error, account_not_found}`

### post_accrued_interest(AccountId, Amount, Description)

Posts accrued interest to an account. Creates a credit entry for interest income.

**Returns:** `{ok, entry_id()} | {error, Reason}`

### get_accrued_interest(AccountId)

Returns the total accrued interest for an account that hasn't yet been posted.

**Returns:** `{ok, amount()} | {error, account_not_found}`

### run_accrual_batch(ProductType, ProductId, AsOfDate)

Runs a batch accrual for all accounts of a given product type. Used for end-of-day or end-of-month interest accrual processing.

**Returns:** `{ok, Summary}` - Summary of accounts processed and total interest accrued

## Example Usage

```erlang
% Calculate interest on $5000 for 30 days at 3.25% APY
{ok, Interest} = cb_interest:calculate_simple_interest(
    500000,     % $5000 in cents
    0.0325,     % 3.25% annual rate
    30          % 30 days
),
io:format("Interest earned: ~.2f~n", [Interest / 100]).

% Accrue interest for a savings account
{ok, Accrued} = cb_interest:accrue_interest(
    AccountId,
    0.0325,     % 3.25% rate
    StartDate,  % Beginning of period
    EndDate     % End of period
),

% Post the accrued interest to the account
cb_interest:post_accrued_interest(
    AccountId,
    Accrued,
    "Monthly interest posting"
).
```

## See Also

- [cb_savings_products](../apps/cb_savings_products/README.md)
- [cb_loans](../apps/cb_loans/README.md)
- [cb_ledger](../apps/cb_ledger/README.md)
