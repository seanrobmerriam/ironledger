# IronLedger Error Catalogue

All error atoms returned by IronLedger functions are defined here. No error atom may be
used in code unless it appears in this catalogue.

HTTP error responses always use:

```json
{ "error": "error_atom", "message": "Human-readable description" }
```

## 1. Account Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `account_not_found` | 404 | No account exists with the given ID |
| `account_frozen` | 409 | Operation rejected; account is in `frozen` status |
| `account_closed` | 409 | Operation rejected; account is in `closed` status |
| `account_has_balance` | 409 | Account closure rejected; balance must be zero before closing |
| `account_already_frozen` | 409 | Freeze rejected; account is already frozen |
| `account_not_frozen` | 409 | Unfreeze rejected; account is not currently frozen |
| `account_currency_immutable` | 422 | Attempt to change currency on an existing account |

## 2. Party Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `party_not_found` | 404 | No party exists with the given ID |
| `party_suspended` | 409 | Operation rejected; party is suspended |
| `party_closed` | 409 | Operation rejected; party is closed |
| `party_has_active_accounts` | 409 | Party closure rejected; party still has non-closed accounts |
| `party_already_suspended` | 409 | Suspend rejected; party is already suspended |
| `party_not_suspended` | 409 | Reactivation rejected; party is not suspended |
| `email_already_exists` | 409 | Party creation rejected; email is already registered |

## 3. Transaction And Ledger Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `insufficient_funds` | 402 | Debit account balance is less than the requested amount |
| `currency_mismatch` | 409 | Source and destination accounts have different currencies |
| `unsupported_currency` | 422 | Currency code is not in the supported set |
| `idempotency_conflict` | 409 | Idempotency key is already used by a different operation type |
| `transaction_not_found` | 404 | No transaction exists with the given ID |
| `transaction_not_posted` | 409 | Reversal rejected; only `posted` transactions can be reversed |
| `transaction_already_reversed` | 409 | Reversal rejected; transaction is already reversed |
| `same_account_transfer` | 422 | Source and destination account IDs are identical |
| `ledger_entry_not_found` | 404 | No ledger entry exists with the given ID |
| `ledger_imbalance` | 500 | Internal debit and credit totals do not match |

## 4. Product, Loan, And Interest Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `product_not_found` | 404 | No savings or loan product exists with the given ID |
| `product_already_active` | 409 | Product activation rejected; product is already active |
| `product_already_inactive` | 409 | Product deactivation rejected; product is already inactive |
| `not_found` | 404 | Generic not-found error still used by parts of the loan code |
| `accrual_not_found` | 404 | No interest accrual exists with the given ID |
| `invalid_interest_type` | 422 | Interest type is not supported for the requested product |
| `invalid_compounding_period` | 422 | Compounding period is not one of the supported values |
| `invalid_interest_rate` | 422 | Interest rate is invalid for the requested operation |
| `interest_rate_too_high` | 422 | Interest rate exceeds the allowed maximum |
| `invalid_term` | 422 | Loan term is not valid |
| `term_too_long` | 422 | Loan term exceeds the supported maximum |
| `invalid_product_id` | 422 | Product identifier is missing or malformed |
| `invalid_status` | 409 | Operation is not allowed for the resource's current status |
| `invalid_parameters` | 422 | Product or interest parameters failed validation |

## 5. Validation Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `missing_required_field` | 422 | A required request field is absent or null |
| `invalid_uuid` | 422 | A field expected to be a UUID has an invalid format |
| `invalid_amount` | 422 | Amount is not a positive integer |
| `amount_overflow` | 422 | Amount exceeds the maximum allowed value (`9_999_999_999_99`) |
| `invalid_currency` | 422 | Currency is not a recognised ISO 4217 code |
| `invalid_json` | 400 | Request body is not valid JSON |
| `invalid_page` | 422 | Page number is less than 1 |
| `invalid_page_size` | 422 | Page size is less than 1 or greater than 100 |
| `invalid_pagination` | 422 | Pagination parameters are malformed or inconsistent |

## 6. System Errors

| Atom | HTTP Status | Description |
|------|-------------|-------------|
| `database_error` | 500 | Mnesia transaction failed unexpectedly |
| `internal_error` | 500 | Unexpected internal error; details logged server-side |
| `not_implemented` | 501 | Endpoint exists in the release contract but is not implemented yet |

## 7. Erlang Usage

Errors are returned as `{error, Atom}` tuples.

```erlang
case cb_accounts:get_account(AccountId) of
    {ok, Account} ->
        Account;
    {error, account_not_found} ->
        handle_not_found()
end.
```

In `cb_integration`, handlers map these atoms to HTTP responses through
`cb_http_errors:to_response/1`.
