# cb_savings_products

Savings product definitions with interest rates and compounding periods.

## Module Overview

The cb_savings_products module defines and manages savings product configurations. A savings product specifies the interest rate, compounding frequency, minimum balance, and other parameters that govern how interest is calculated and credited to savings accounts.

## Key Concepts

### Interest Rates

Annual interest rate expressed as a decimal (e.g., 0.05 for 5%). Rates can be fixed or variable.

### Compounding Periods

- `daily` - Interest compounded every day
- `monthly` - Interest compounded monthly
- `quarterly` - Interest compounded quarterly
- `annually` - Interest compounded annually

### Minimum Balance

Minimum account balance required to earn interest. Accounts below this threshold may earn reduced or no interest.

## Types

### product_id()
UUID binary for savings product identification.

### interest_rate()
Annual interest rate as decimal (e.g., 0.05 = 5%).

### compounding_period()
Atom: `daily` | `monthly` | `quarterly` | `annually`

## Functions

### create_product(ProductName, InterestRate, CompoundingPeriod, MinBalance, Currency)

Creates a new savings product definition with specified interest parameters.

**Parameters:**
- `ProductName` - Human-readable name
- `InterestRate` - Annual rate (decimal)
- `CompoundingPeriod` - How often interest compounds
- `MinBalance` - Minimum balance to earn interest
- `Currency` - ISO 4217 currency code

**Returns:** `{ok, product_id()} | {error, Reason}`

### get_product(ProductId)

Retrieves savings product details.

**Returns:** `{ok, product()} | {error, product_not_found}`

### list_products()

Returns all available savings products.

**Returns:** `{ok, [product()]}`

### calculate_interest(ProductId, Amount, Days)

Calculates interest earned for a given principal and number of days using the product's interest rate and compounding rules.

**Returns:** `{ok, amount()} | {error, product_not_found}`

### update_product(ProductId, Updates)

Updates product parameters. Existing accounts using this product will use the new parameters for future interest calculations.

**Returns:** `{ok, product_id()} | {error, product_not_found}`

## Example Usage

```erlang
% Create a savings product
{ok, ProductId} = cb_savings_products:create_product(
    "Premium Savings",
    0.0325,    % 3.25% annual rate
    monthly,    % compound monthly
    100000,     % $1000 minimum balance
    'USD'
),

% Calculate interest for $5000 over 30 days
{ok, Interest} = cb_savings_products:calculate_interest(
    ProductId,
    500000,     % $5000 in cents
    30
),
io:format("Interest earned: ~p~n", [Interest]).
```

## See Also

- [cb_interest](../apps/cb_interest/README.md)
- [cb_ledger](../apps/cb_ledger/README.md)
