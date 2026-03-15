# cb_party

Customer/party management - create, suspend, reactivate, and close party records.

## Module Overview

The cb_party module manages party (customer) records. A party represents an individual or entity that owns accounts in the banking system. The module handles the complete party lifecycle including creation, status changes, and closure.

## Party Status

- `active` - Party is active and can own accounts
- `suspended` - Party is temporarily restricted
- `closed` - Party is permanently closed

## Types

### party_id()
UUID binary for unique party identification.

### party_status()
Atom: `active` | `suspended` | `closed`

### party_type()
Atom: `individual` | `corporate`

## Functions

### create_party(PartyType, PartyDetails)

Creates a new party (customer) record. Party details should include name, address, identification, and contact information.

**Returns:** `{ok, party_id()} | {error, Reason}`

### get_party(PartyId)

Retrieves party details including status, type, name, and account references.

**Returns:** `{ok, party()} | {error, party_not_found}`

### suspend_party(PartyId, Reason)

Suspends a party, restricting all their accounts. This is typically used for regulatory or compliance reasons.

**Returns:** `{ok, party_id()} | {error, party_not_found} | {error, party_closed}`

### reactivate_party(PartyId, Reason)

Reactivates a suspended party, restoring full access to their accounts.

**Returns:** `{ok, party_id()} | {error, party_not_found} | {error, party_not_suspended}`

### close_party(PartyId, Reason)

Permanently closes a party. All accounts must be closed with zero balance before the party can be closed.

**Returns:** `{ok, party_id()} | {error, party_not_found} | {error, party_has_open_accounts} | {error, party_already_closed}`

### list_parties()

Returns all parties in the system. For administrative use.

**Returns:** `{ok, [party()]}`

## See Also

- [cb_accounts](../apps/cb_accounts/README.md)
- [Architecture](../docs/architecture.md)
