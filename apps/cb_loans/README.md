# cb_loans

Loan management - products, accounts, repayments, and interest calculations.

## Module Overview

The cb_loans module handles the complete loan lifecycle including loan products (definitions), loan accounts (borrowings), repayment schedules, and amortization calculations.

## Key Concepts

### Loan Products

Defines loan types with interest rates, terms, and fees. Examples: "Personal Loan 5%", "Mortgage 30Y".

### Loan Accounts

Represents an active loan borrowing from a loan product. Tracks principal, interest accrual, and repayment status.

### Repayments

Payments made against the loan principal and interest. Can be scheduled (amortization) or manual.

## Loan Status

- `disbursed` - Loan is active, money has been disbursed
- `fully_paid` - Loan is completely repaid
- `defaulted` - Loan has exceeded payment threshold
- `written_off` - Loan has been written off

## Types

### loan_id()
UUID binary for loan account identification.

### loan_product_id()
UUID binary for loan product definition.

### loan_status()
Atom: `disbursed` | `fully_paid` | `defaulted` | `written_off`

## Functions

### create_loan_product(ProductName, InterestRate, TermMonths, Currency, Options)

Creates a new loan product definition with interest rate, term length, and other parameters.

**Returns:** `{ok, loan_product_id()} | {error, Reason}`

### disburse_loan(PartyId, LoanProductId, Amount, DisbursementAccount, IdempotencyKey)

Creates a new loan account and disburses funds to the specified account. Starts interest accrual.

**Returns:** `{ok, loan_id()} | {error, Reason}`

### get_loan(LoanId)

Retrieves loan details including principal, accrued interest, remaining balance, and status.

**Returns:** `{ok, loan()} | {error, loan_not_found}`

### make_repayment(LoanId, Amount, IdempotencyKey, Description)

Records a loan repayment. Applies payment to interest first, then principal (per standard amortization rules).

**Returns:** `{ok, repayment_id()} | {error, loan_not_found} | {error, loan_closed}`

### calculate_amortization(LoanProductId, Principal, StartDate)

Calculates the full amortization schedule for a loan given principal and product terms. Returns periodic payment amounts.

**Returns:** `{ok, [amortization_entry()]} | {error, product_not_found}`

### get_repayment_schedule(LoanId)

Returns the expected repayment schedule for a loan based on its product and disbursement date.

**Returns:** `{ok, [schedule_entry()]}`

### write_off_loan(LoanId, Reason)

Writes off an unpaid loan. Marks the loan as written_off and stops interest accrual.

**Returns:** `{ok, loan_id()} | {error, loan_not_found}`

## Example Usage

```erlang
% Create a loan product and disburse a loan
{ok, ProductId} = cb_loans:create_loan_product(
    "Personal Loan 8%",
    0.08,       % 8% annual rate
    36,         % 36 months term
    'USD',
    #{min_amount => 1000000, max_amount => 50000000}
),

% Disburse $10,000 loan
{ok, LoanId} = cb_loans:disburse_loan(
    PartyId,
    ProductId,
    1000000,    % $10,000 in cents
    AccountId,
    uuid:gen_v4()
),

% Calculate what the monthly payment will be
{ok, Schedule} = cb_loans:calculate_amortization(
    ProductId,
    1000000,
    erlang:system_time(millisecond)
),
hd(Schedule).  % Returns first payment amount
```

## See Also

- [cb_interest](../apps/cb_interest/README.md)
- [cb_ledger](../apps/cb_ledger/README.md)
