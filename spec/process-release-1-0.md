---
title: IronLedger 1.0 Release Specification
version: 1.0
date_created: 2026-03-21
last_updated: 2026-03-21
owner: Sean
tags: [process, release, product, dashboard, docker]
---

# Introduction

This specification defines what "IronLedger 1.0" means as a downloadable, deployable product. The target outcome is not a prototype codebase. The target outcome is a packaged release that a user can run with `docker compose` and use through the browser dashboard without manual wiring.

## 1. Purpose & Scope

The purpose of this specification is to define the minimum complete 1.0 release for IronLedger.

Audience:
- Maintainers implementing 1.0
- AI agents generating implementation tasks
- Reviewers validating release readiness

Scope:
- Release packaging
- Docker-based deployment
- OTP backend startup
- Dashboard availability
- End-user workflows for all currently intended product functions
- Documentation required to deploy and operate 1.0 locally

Out of scope for 1.0 unless later added explicitly:
- Authentication and authorization
- Multi-node clustering
- Production TLS termination
- Horizontal scaling
- Cross-currency transfers
- External payment rails

## 2. Definitions

- **Dashboard**: The Go WebAssembly browser user interface located in `apps/cb_dashboard/`.
- **Current functions**: User-facing banking and product-management workflows already represented in the repository by modules, routes, handlers, or domain APIs.
- **Deployable**: A clean checkout can be started using documented Docker commands without local Erlang or Go toolchain setup.
- **Working**: The dashboard loads, the backend responds successfully, and supported workflows complete through the UI.
- **1.0 release artifact**: The repository state, Docker assets, documentation, and runtime configuration necessary to start and use IronLedger as a packaged application.

## 3. Requirements, Constraints & Guidelines

- **REQ-001**: IronLedger 1.0 shall be runnable with `docker compose up` from the repository root.
- **REQ-002**: IronLedger 1.0 shall include a backend container that starts the Erlang applications required for all 1.0 workflows.
- **REQ-003**: IronLedger 1.0 shall include a dashboard container or equivalent static-serving path so the browser UI is reachable after `docker compose up`.
- **REQ-004**: The dashboard shall expose working workflows for party management, account management, transfers, deposits, withdrawals, transaction inquiry, ledger inquiry, and product management.
- **REQ-005**: Product management in 1.0 shall include savings product creation, listing, and detail workflows.
- **REQ-006**: Product management in 1.0 shall include loan product creation, listing, and detail workflows.
- **REQ-007**: Loan lifecycle management in 1.0 shall include create, approve, disburse, view, and repayment workflows end-to-end through the packaged runtime and dashboard.
- **REQ-008**: Every route exposed by the running 1.0 system shall be backed by started OTP applications, required Mnesia tables, and dashboard or API documentation.
- **REQ-009**: No route may be exposed by default if it returns `500` because its application is not started or its schema is not initialized.
- **REQ-010**: The release shall include a health endpoint and documented container healthchecks.
- **REQ-011**: The release shall include user-facing setup documentation for download, startup, URL access, and shutdown.
- **REQ-012**: The release shall include a reproducible build path for the Wasm artifact and `wasm_exec.js`.
- **REQ-013**: The release shall preserve the repository's integer-only monetary model for balances and transaction amounts.
- **REQ-014**: The release shall pass `rebar3 compile`, `rebar3 ct`, `rebar3 dialyzer`, and `rebar3 proper`.
- **REQ-015**: The dashboard code shall pass `GOOS=js GOARCH=wasm go vet ./...`.
- **REQ-016**: The backend shall start without manual shell steps beyond the documented Docker workflow.

- **CON-001**: The 1.0 definition must be achievable from the current repository structure and OTP architecture.
- **CON-002**: Docker deployment shall not require a user to install Erlang, rebar3, or Go on the host.
- **CON-003**: Mnesia persistence strategy for 1.0 must be explicit. If persistence is supported, the compose file must mount storage.
- **CON-004**: A feature is not considered in scope for 1.0 merely because code exists. It must be started, tested, documented, and reachable through the packaged UI.

- **GUD-001**: Prefer one primary dashboard URL and one primary API URL in local deployment.
- **GUD-002**: Prefer deterministic container startup with explicit dependency order and healthchecks.
- **GUD-003**: Prefer hiding incomplete product areas rather than shipping them partially.

## 4. Interfaces & Data Contracts

### 4.1 Deployment Interface

The user-facing deployment interface shall be:

```bash
docker compose up --build
```

Expected post-conditions:
- Dashboard reachable in browser
- Backend reachable on documented API port
- Healthcheck endpoint returns success

### 4.2 Required User Workflows

| Workflow | Backend Surface | Dashboard Requirement |
|---|---|---|
| Create party | `cb_party`, `cb_integration` handlers | Form + list refresh + error display |
| Suspend/reactivate/close party | `cb_party`, handlers | Action controls + state updates |
| Create account | `cb_accounts`, handlers | Form + party-scoped account listing |
| Freeze/unfreeze/close account | `cb_accounts`, handlers | Action controls + state updates |
| View balance | `cb_accounts:get_balance/1` | Account detail display |
| Deposit | `cb_payments:deposit/5` | Form + success/error feedback |
| Withdraw | `cb_payments:withdraw/5` | Form + success/error feedback |
| Transfer | `cb_payments:transfer/6` | Form + success/error feedback |
| Reverse transaction | `cb_payments:reverse_transaction/1` | Transaction detail action |
| View transaction detail | transaction handler | Transaction detail page/view |
| View ledger entries | ledger handlers | Account/transaction ledger view |
| Create savings product | savings handlers | Product form + list/detail |
| List and view savings products | savings handlers | Product list/detail views |
| Create loan product | loan product handlers | Product form + list/detail |
| List and view loan products | loan product handlers | Product list/detail views |
| Create and progress loan | loan handlers | Create/view/approve/disburse/repay |

### 4.3 Release Contracts

| Contract | Required State |
|---|---|
| Router contract | Every enabled route must be backed by started code |
| Schema contract | Every enabled feature must create its required tables on startup |
| Dashboard contract | Every visible dashboard action must call a live API route |
| Error contract | API errors must use `{"error": "...", "message": "..."}` |

## 5. Acceptance Criteria

- **AC-001**: Given a clean checkout, when a user runs `docker compose up --build`, then IronLedger starts without manual host-language setup.
- **AC-002**: Given the stack is running, when a user opens the documented dashboard URL, then the dashboard loads successfully and shows no blocking runtime errors.
- **AC-003**: Given the dashboard is loaded, when a user creates a party and then creates an account, then both operations succeed through the UI and are visible after refresh.
- **AC-004**: Given two active accounts with funds, when a user performs a transfer through the dashboard, then balances and transaction history update correctly.
- **AC-005**: Given a posted transaction, when a user reverses it through the dashboard, then the reversal completes and ledger history reflects the change.
- **AC-006**: Given the dashboard is loaded, when a user opens the product areas, then savings product and loan product creation, listing, and detail workflows are available and functional.
- **AC-007**: Given the dashboard is loaded, when a user performs loan create, approve, disburse, and repayment workflows, then each step succeeds end-to-end against the packaged backend.
- **AC-008**: Given the running 1.0 stack, when a user accesses any enabled banking, product, or loan route, then the route is backed by started applications and initialized schema rather than returning startup-related `500` responses.
- **AC-009**: The repository shall pass `rebar3 compile`, `rebar3 ct`, `rebar3 dialyzer`, `rebar3 proper`, and `GOOS=js GOARCH=wasm go vet ./...` before 1.0 is declared complete.

## 6. Test Automation Strategy

- **Test Levels**: Compile, Dialyzer, Common Test, PropEr, dashboard build/vet, container smoke tests, end-to-end browser tests.
- **Frameworks**: rebar3, Common Test, PropEr, Go toolchain, Docker Compose, browser automation for dashboard smoke flows.
- **Test Data Management**: Use isolated Mnesia state per test run; use disposable container volumes for compose tests.
- **CI/CD Integration**: The 1.0 branch should run backend validation, Wasm validation, and compose smoke tests on every merge candidate.
- **Coverage Requirements**: All public backend functions in 1.0 scope require CT coverage; all monetary arithmetic paths require PropEr coverage.
- **Performance Testing**: Limited local smoke targets only; no scale target is required for 1.0.

## 7. Rationale & Context

The current repository has strong core banking behavior but is not yet packaged as a product. A user cannot currently rely on Docker deployment, and some feature surfaces exist in code without being fully wired into default startup. The 1.0 definition therefore must optimize for coherence, packaging, and end-to-end usability across both the core banking features and the product or loan domains that are now explicitly in scope.

The key product decision is that "all current functions" includes savings products, loan products, loans, and repayments. Those areas must therefore be promoted from partial code to supported release functionality. This prevents shipping dead routes, incomplete UIs, or modules that only work in a development shell.

## 8. Dependencies & External Integrations

### External Systems
- **EXT-001**: Docker Engine with Compose support for local deployment.

### Third-Party Services
- **SVC-001**: None required for local 1.0 deployment.

### Infrastructure Dependencies
- **INF-001**: Container runtime capable of running Erlang release and static dashboard serving.
- **INF-002**: Persistent volume support if Mnesia persistence is retained across container restarts.

### Data Dependencies
- **DAT-001**: No external data source is required for local 1.0 operation.

### Technology Platform Dependencies
- **PLT-001**: Erlang/OTP runtime compatible with current rebar3 build.
- **PLT-002**: Go toolchain for build-time Wasm artifact generation in containerized or CI environments.

### Compliance Dependencies
- **COM-001**: None mandated for prototype-level 1.0 beyond internal money-handling rules already defined in the repository.

## 9. Examples & Edge Cases

```text
Edge case 1:
- Savings and loan modules exist in source but are not started in the default release.
- Correct 1.0 behavior: wire them into startup, schema, tests, Docker packaging, and dashboard flows before declaring 1.0 complete.

Edge case 2:
- Dashboard loads but some buttons target disabled routes.
- Correct 1.0 behavior: UI must not expose actions that fail solely because the runtime is incomplete.

Edge case 3:
- Containers start but Wasm asset is missing or mismatched with wasm_exec.js.
- Correct 1.0 behavior: build pipeline and image packaging must include both assets deterministically.
```

## 10. Validation Criteria

- 1.0 validation is complete only when all required backend, dashboard, and compose checks are green.
- A reviewer must be able to follow the README deployment steps exactly and reach a working dashboard.
- Every enabled feature in the dashboard must be usable without dropping into `rebar3 shell`.

## 11. Related Specifications / Further Reading

- [Feature PRD](/home/sean/workspace/projects/ironledger/docs/feature-prd.md)
- [Architecture](/home/sean/workspace/projects/ironledger/docs/architecture.md)
- [Testing Strategy](/home/sean/workspace/projects/ironledger/docs/testing-strategy.md)
- [API Contract](/home/sean/workspace/projects/ironledger/docs/api-contract.yaml)
