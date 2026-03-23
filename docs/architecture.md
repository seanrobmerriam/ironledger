# System Architecture

High-level architecture of the IronLedger core banking system.

## Overview

IronLedger is built on Erlang/OTP, a fault-tolerant, distributed platform designed for telecom-grade reliability. The system follows the OTP (Open Telecom Platform) design patterns with a layered architecture.

## Application Layer

### cb_ledger

The core of the accounting system. Maintains the double-entry ledger and ensures the accounting equation always balances. All financial transactions flow through here.

### cb_accounts

Manages bank accounts - creation, status changes (freeze/unfreeze/close), and balance inquiries. Depends on cb_ledger for ledger entries.

### cb_payments

Handles payment operations - transfers, deposits, withdrawals. Implements idempotency to prevent duplicate transactions. Uses cb_ledger for entry posting.

### cb_party

Customer/party management. Maintains the relationship between customers and their accounts. Used for KYC/AML compliance.

### cb_savings_products

Defines savings account products with interest rates, compounding periods, and minimum balance requirements.

### cb_loans

Loan management - products, disbursements, repayments, amortization calculations. Works with cb_interest for interest calculations.

### cb_interest

Interest calculation engine - simple and compound interest, daily accruals, batch processing for interest posting.

### cb_integration

HTTP API layer using Cowboy. Exposes REST endpoints for all banking operations. Handles JSON serialization and error formatting.

## Data Layer

### Mnesia

Erlang's distributed database. All financial data is stored in Mnesia tables:

- **RAM + Disk** - Tables use both memory and disk storage
- **Transactions** - All writes use `mnesia:transaction/1`
- **Replication** - Can be configured for distributed deployment

### Table Structure

- **accounts** - Account records with status, type, currency
- **ledger_entries** - Individual debit/credit entries
- **parties** - Customer records
- **payments** - Payment transactions
- **idempotency_keys** - Tracks processed requests

## Supervision Trees

Each OTP application has a supervision tree that manages process lifecycles and provides fault tolerance.

```erlang
% Example supervision tree for cb_ledger
{cb_ledger_sup, [],
    {one_for_one, 5, 3600},
    [
        {cb_ledger, {cb_ledger, start_link, []},
            permanent, 5000, worker, [cb_ledger]}
    ]}
```

## API Layer

### Cowboy HTTP Server

Erlang HTTP server handling incoming requests. Runs as an OTP application with its own supervision tree.

### Middleware Pipeline

- **CORS** - Cross-origin resource sharing
- **Logging** - Request/response logging
- **Routing** - Dispatch to handlers

### Request Flow

```
HTTP Request → Cowboy Middleware → Router → Handler → Business Logic → Mnesia → JSON Response
```

## Key Design Principles

- **Double-Entry Bookkeeping** - Every transaction has equal debits and credits
- **Idempotent Payments** - UUID-based idempotency prevents duplicates
- **Immutable Ledger** - Entries are append-only, corrections are new entries
- **Supervision Trees** - Fault isolation and automatic recovery
- **Transactions** - All financial operations are atomic
- **Type Safety** - Dialyzer ensures type correctness
