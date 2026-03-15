# cb_accounts

Account lifecycle management - create, freeze, unfreeze, and close bank accounts.

## Module Overview

The cb_accounts module manages the complete lifecycle of bank accounts. It handles account creation, status changes (freeze, unfreeze, close), and maintains the relationship between accounts and parties (customers).

## Account Status

Accounts can be in one of the following states:

- `active` - Account is open and fully operational
- `frozen` - Account is temporarily locked, no debits allowed
- `closed` - Account is permanently closed

## Types

### account_id()
UUID binary for unique account identification.

### account_status()
Atom: `active` | `frozen` | `closed`

### account_type()
Atom: `checking` | `savings` | `loan` | `internal`

### party_id()
UUID binary for the party (customer) who owns the account.

## Functions

### create_party(PartyId, AccountType, Currency, InitialBalance)

Creates a new bank account for a party. Creates the account record and initializes the ledger entry if initial balance is provided.

**Parameters:**
- `PartyId` - Owner's party UUID
- `AccountType` - Type of account
- `Currency` - ISO 4217 currency code
- `InitialBalance` - Opening balance in minor units

**Returns:** `{ok, account_id()} | {error, Reason}`

### get_account(AccountId)

Retrieves account details including status, type, currency, balance, and timestamps.

**Returns:** `{ok, account()} | {error, account_not_found}`

### freeze_account(AccountId, Reason)

Freezes an account, preventing debit transactions. Credits (deposits) are still allowed. The reason is recorded in the audit log.

**Returns:** `{ok, account_id()} | {error, account_not_found} | {error, account_closed} | {error, account_already_frozen}`

### unfreeze_account(AccountId, Reason)

Reactivates a frozen account, restoring full transaction capability.

**Returns:** `{ok, account_id()} | {error, account_not_found} | {error, account_closed} | {error, account_not_frozen}`

### close_account(AccountId, Reason)

Permanently closes an account. Account must have zero balance before closing. After closing, no transactions are allowed.

**Returns:** `{ok, account_id()} | {error, account_not_found} | {error, account_not_zero_balance} | {error, account_already_closed}`

### list_accounts(PartyId)

Returns all accounts owned by a party.

**Returns:** `{ok, [account()]}`

### get_balance(AccountId)

Gets the current balance of an account. Delegates to cb_ledger for the actual balance calculation.

**Returns:** `{ok, amount()} | {error, account_not_found}`

## Example Usage

```erlang
% Create a new checking account for a customer
PartyId = <<"550e8400-e29b-41d4-a716-446655440000">>,

case cb_accounts:create_account(PartyId, checking, 'USD', 100000) of
    {ok, AccountId} ->
        io:format("Created account: ~p~n", [AccountId]),
        
        % Freeze the account for investigation
        cb_accounts:freeze_account(AccountId, "Suspected fraud"),
        
        % Later, unfreeze after review
        cb_accounts:unfreeze_account(AccountId, "Cleared investigation");
        
    {error, Reason} ->
        io:format("Error creating account: ~p~n", [Reason])
end.
```

## See Also

- [cb_ledger](../apps/cb_ledger/README.md)
- [cb_party](../apps/cb_party/README.md)
