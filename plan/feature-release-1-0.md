---
goal: IronLedger 1.0 Deliverable Plan
version: 1.0
date_created: 2026-03-21
last_updated: 2026-03-22
owner: Sean
status: In progress
tags: [feature, release, docker, dashboard, backend]
---

# Introduction

![Status: In progress](https://img.shields.io/badge/status-In%20progress-yellow)

This plan converts the current IronLedger repository into a downloadable 1.0 release that starts with Docker Compose and exposes all required banking, savings product, loan product, loan, and repayment workflows through the dashboard.

## 1. Requirements & Constraints

- **REQ-001**: `docker compose up --build` from the repository root must start a usable backend and dashboard without host Erlang or Go installation.
- **REQ-002**: The 1.0 runtime must start `cb_party`, `cb_accounts`, `cb_payments`, `cb_ledger`, `cb_integration`, `cb_savings_products`, `cb_loans`, and `cb_interest`.
- **REQ-003**: The 1.0 dashboard must support party management, account management, transfers, deposits, withdrawals, transaction inquiry, ledger inquiry, savings product management, loan product management, loan creation, loan approval, loan disbursement, loan detail viewing, and loan repayment.
- **REQ-004**: Every enabled route in `apps/cb_integration/src/cb_router.erl` must be backed by started applications, initialized Mnesia tables, mapped API errors, and an implemented dashboard or documented API-only workflow.
- **REQ-005**: Monetary amounts must remain integer minor units end-to-end.
- **REQ-006**: Savings and loan rate handling must be migrated away from floats and represented as integer basis points in code, API payloads, tests, and documentation.
- **REQ-007**: Loan disbursement and repayment must post through the core accounting path rather than only mutating loan records.
- **REQ-008**: Interest accrual and posting must use valid internal accounts or an explicit ledger strategy that can run in the packaged runtime.
- **REQ-009**: All product, loan, and interest error atoms returned by backend code must be present in `docs/error-catalogue.md` and mapped in `apps/cb_integration/src/cb_http_errors.erl`.
- **REQ-010**: The repository must pass `rebar3 compile`, `rebar3 ct`, `rebar3 dialyzer`, `rebar3 proper`, and `GOOS=js GOARCH=wasm go vet ./...` before release signoff.
- **REQ-011**: The compose stack must include deterministic healthchecks and documented URLs for the dashboard and API.
- **CON-001**: Product and loan features may not be hidden or excluded from the default runtime for 1.0.
- **CON-002**: No route may be re-enabled in the router until its startup path, schema, error mapping, and tests are in place.
- **CON-003**: New Erlang code must keep exported function specs and transaction-safe Mnesia access.
- **CON-004**: New Go dashboard code must build as Wasm and keep all API communication on JSON integer fields for money.
- **PAT-001**: Deliver 1.0 as validated vertical slices: contract, domain model, runtime wiring, dashboard workflow, packaging, then release validation.

## 2. Implementation Steps

### Implementation Phase 1

- GOAL-001: Freeze the 1.0 external contract so backend, dashboard, and Docker work against one exact feature definition.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Update `docs/api-contract.yaml` to declare the exact 1.0 product and loan routes, including savings products, loan products, loans, loan actions, and repayment endpoints. Replace float rate fields with integer basis-point fields in all request and response schemas. |  |  |
| TASK-002 | Update `spec/process-release-1-0.md` and `docs/feature-prd.md` so 1.0 explicitly requires the route set restored in `apps/cb_integration/src/cb_router.erl`, the dashboard workflows in `apps/cb_dashboard/`, and the basis-point contract for rates. |  |  |
| TASK-003 | Update `docs/error-catalogue.md` to include all product, loan, and interest atoms currently emitted by `apps/cb_savings_products/src/cb_savings_products.erl`, `apps/cb_loans/src/cb_loan_products.erl`, `apps/cb_loans/src/cb_loan_accounts.erl`, `apps/cb_loans/src/cb_loan_calculations.erl`, `apps/cb_loans/src/cb_loan_repayments.erl`, and `apps/cb_interest/src/*.erl`. |  |  |
| TASK-004 | Update `apps/cb_integration/src/cb_http_errors.erl` so every catalogued product, loan, and interest error atom maps to an intentional HTTP status and JSON response. Eliminate fallback `500` responses caused by unmapped business errors. |  |  |
| TASK-005 | Update `README.md` to define the 1.0 workflow list and make clear that savings products, loan products, loans, and repayments are mandatory, dashboard-backed features in the shipped release. |  |  |

### Implementation Phase 2

- GOAL-002: Replace float-based savings, loan, and interest modeling with integer-safe rate handling that matches the repository money rules.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Change rate types in `apps/cb_interest/include/cb_interest.hrl`, `apps/cb_savings_products/include/savings_product.hrl`, and `apps/cb_loans/include/loan.hrl` from `float()` to integer basis points and update related `-type` and record documentation. |  |  |
| TASK-007 | Rewrite `apps/cb_interest/src/cb_interest.erl` to remove `round/1`, `trunc/1`, and float division from monetary paths. Keep calculations integer-safe, add overflow protection, and expose conversion helpers only if they are not used on money values. |  |  |
| TASK-008 | Rewrite `apps/cb_interest/src/cb_interest_accrual.erl` and `apps/cb_interest/src/cb_interest_posting.erl` so accrual creation, daily-rate storage, and posting logic use basis points and integer arithmetic rather than float daily rates. |  |  |
| TASK-009 | Rewrite `apps/cb_loans/src/cb_loan_calculations.erl` so monthly payment, total interest, and repayment math use integer-safe formulas and validated basis points instead of decimal fractions. |  |  |
| TASK-010 | Update `apps/cb_savings_products/src/cb_savings_products.erl`, `apps/cb_loans/src/cb_loan_products.erl`, and `apps/cb_loans/src/cb_loan_accounts.erl` to validate, persist, and return rates as basis points. Update all handler serialization in `apps/cb_integration/src/handlers/cb_savings_products*.erl`, `apps/cb_integration/src/handlers/cb_loan_products_handler.erl`, and `apps/cb_integration/src/handlers/cb_loans_handler.erl` to match the new JSON contract. |  |  |
| TASK-011 | Update all affected tests in `apps/cb_savings_products/test/`, `apps/cb_loans/test/`, and `apps/cb_interest/test/` so their fixtures and assertions use integer basis points and no longer assert float behavior. |  |  |

### Implementation Phase 3

- GOAL-003: Make the backend runtime self-starting and internally coherent for savings, loans, and interest.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Update `rebar.config` release application ordering so the packaged runtime starts `cb_savings_products`, `cb_loans`, and `cb_interest` in addition to the existing core apps. |  |  |
| TASK-013 | Update `apps/cb_integration/src/cb_integration.app.src` and any affected `*.app.src` files so application dependencies reflect the product, loan, and interest modules used by the HTTP layer. |  |  |
| TASK-014 | Extend `apps/cb_integration/src/cb_schema.erl` to create the non-core tables that are not created deterministically elsewhere, including `savings_product` and `interest_accrual`, or move those responsibilities into application startup modules and document one consistent ownership model. |  |  |
| TASK-015 | Audit and fix `apps/cb_savings_products/src/cb_savings_products_app.erl`, `apps/cb_savings_products/src/cb_savings_products_sup.erl`, `apps/cb_loans/src/cb_loans_app.erl`, `apps/cb_loans/src/cb_loans_sup.erl`, `apps/cb_interest/src/cb_interest_app.erl`, and `apps/cb_interest/src/cb_interest_sup.erl` so required workers and table initialization run cleanly at startup. |  |  |
| TASK-016 | Restore savings, loan product, loan, and repayment routes in `apps/cb_integration/src/cb_router.erl` only after Tasks 012 through 015 are complete. Wire them to `cb_savings_products_handler`, `cb_savings_products_list_handler`, `cb_loan_products_handler`, `cb_loans_handler`, and `cb_loan_repayments_handler`. |  |  |
| TASK-017 | Fix handler request validation and binding logic in the product and loan handlers so all route params, query params, and JSON bodies use the same field names as `docs/api-contract.yaml` and return mapped business errors instead of startup or parsing failures. |  |  |
| TASK-018 | Rewrite `apps/cb_loans/src/cb_loan_accounts.erl` so `do_disburse_loan/1` performs a real funds movement through the core transaction or ledger layer and not only a loan status update. Define the destination and offset-account strategy explicitly in code and docs. |  |  |
| TASK-019 | Rewrite loan repayment flow across `apps/cb_loans/src/cb_loan_accounts.erl` and `apps/cb_loans/src/cb_loan_repayments.erl` so repayment records and outstanding balances are driven by an actual posted transaction path and not by isolated table mutation alone. |  |  |
| TASK-020 | Replace the synthetic account IDs in `apps/cb_interest/src/cb_interest_posting.erl` with a startup-provisioned system-account strategy or another concrete ledger design that can exist in a fresh Docker deployment. |  |  |

### Implementation Phase 4

- GOAL-004: Add complete dashboard support for the 1.0 product and loan surface.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Extend `apps/cb_dashboard/app.go` state and navigation so the dashboard has explicit views for savings products, loan products, loans, loan detail, and repayments in addition to the current banking views. |  |  |
| TASK-022 | Extend `apps/cb_dashboard/api.go` with fetch helpers for create, list, and detail actions for savings products, loan products, loans, approval, disbursement, and repayments. Match the exact route and JSON contract from `docs/api-contract.yaml`. |  |  |
| TASK-023 | Extend `apps/cb_dashboard/views.go` with forms, tables, and detail panels for savings products and loan products. Include create workflows, list refresh, selection, and error display. |  |  |
| TASK-024 | Extend `apps/cb_dashboard/views.go` with loan workflow UI for create, approve, disburse, repay, and detail viewing. Ensure each action refreshes the relevant list or detail state after success. |  |  |
| TASK-025 | Standardize dashboard success and error behavior in `apps/cb_dashboard/app.go` and `apps/cb_dashboard/api.go` so all create and action flows show user-facing messages and log backend error atoms consistently. |  |  |
| TASK-026 | Add deterministic dashboard asset build output for `apps/cb_dashboard/dist/ironledger.wasm`, `apps/cb_dashboard/dist/wasm_exec.js`, and the served HTML entrypoint used by Docker packaging. |  |  |

### Implementation Phase 5

- GOAL-005: Package the backend and dashboard into a one-command Docker deployment.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-027 | Create a backend image build path using a root-level `Dockerfile` or dedicated backend Dockerfile that compiles the Erlang release, includes runtime config, and starts IronLedger non-interactively. |  |  |
| TASK-028 | Create a dashboard image build path that compiles the Wasm artifact, copies `wasm_exec.js`, and serves the static dashboard over HTTP without requiring a host Go toolchain. |  |  |
| TASK-029 | Create `docker-compose.yml` at the repository root with backend and dashboard services, explicit ports, healthchecks, dependency order, and any volumes required for Mnesia persistence. |  |  |
| TASK-030 | Update `config/sys.config`, `config/vm.args`, and any image entrypoint configuration so the compose stack can set the HTTP port, Mnesia path, and runtime environment deterministically. |  |  |
| TASK-031 | Validate the full stack from a clean checkout with `docker compose up --build`, then capture the exact URLs and smoke-test commands in `README.md`. | x | 2026-03-22 |

### Implementation Phase 6

- GOAL-006: Close the testing and release-readiness gaps for the full 1.0 scope.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-032 | Add or expand Common Test coverage in `apps/cb_integration/test/` for the restored savings product, loan product, loan, and repayment HTTP handlers, including happy paths and mapped error paths. |  |  |
| TASK-033 | Add or expand Common Test coverage in `apps/cb_savings_products/test/`, `apps/cb_loans/test/`, and `apps/cb_interest/test/` for startup behavior, schema assumptions, disbursement, repayment, and interest posting. |  |  |
| TASK-034 | Create PropEr suites under the relevant `apps/*/test/` directories for integer monetary invariants in `cb_interest`, `cb_loan_calculations`, repayment allocation, and any new basis-point conversion helpers required by 1.0. Ensure `rebar3 proper` executes real properties rather than `0/0`. |  |  |
| TASK-035 | Add dashboard-level browser automation for the full happy-path flow: create party, create account, create savings product, create loan product, create loan, approve loan, disburse loan, repay loan, and verify refreshed state. | x | 2026-03-22 |
| TASK-036 | Define and run the final release gate: `rebar3 compile`, `rebar3 ct`, `rebar3 dialyzer`, `rebar3 proper`, `GOOS=js GOARCH=wasm go vet ./...`, dashboard Wasm build, and compose smoke tests. Record evidence in a release checklist document. | x | 2026-03-22 |

## 3. Alternatives

- **ALT-001**: Ship 1.0 with only the original core banking routes. This was rejected because the chosen 1.0 scope explicitly includes savings products, loan products, loans, and repayments.
- **ALT-002**: Re-enable the existing product and loan routes without refactoring float-based rate logic. This was rejected because it violates the repository money rules and would ship inconsistent financial behavior.
- **ALT-003**: Keep product and loan APIs live but defer dashboard support. This was rejected because the 1.0 definition requires a working dashboard for all current functions.
- **ALT-004**: Leave disbursement and repayment as loan-table-only mutations. This was rejected because 1.0 requires end-to-end financial behavior grounded in the core ledger or payments path.

## 4. Dependencies

- **DEP-001**: `docs/api-contract.yaml` must define the same route and payload contract used by the backend handlers and dashboard fetch code.
- **DEP-002**: `docs/error-catalogue.md` and `apps/cb_integration/src/cb_http_errors.erl` must stay synchronized for all product, loan, and interest failures.
- **DEP-003**: `rebar.config` and `apps/*/*.app.src` must start the same application set expected by `apps/cb_integration/src/cb_router.erl`.
- **DEP-004**: `apps/cb_integration/src/cb_schema.erl` or equivalent startup modules must create all tables required by the restored 1.0 route surface.
- **DEP-005**: `apps/cb_dashboard/api.go`, `apps/cb_dashboard/app.go`, and `apps/cb_dashboard/views.go` must advance together because the dashboard has no existing product or loan surface.
- **DEP-006**: The Docker packaging work depends on completed backend startup wiring and a reproducible Wasm asset build.
- **DEP-007**: The final release gate depends on adding actual PropEr properties; `rebar3 proper` is currently non-failing but empty.

## 5. Files

- **FILE-001**: `/home/sean/workspace/projects/ironledger/docs/api-contract.yaml`
- **FILE-002**: `/home/sean/workspace/projects/ironledger/docs/error-catalogue.md`
- **FILE-003**: `/home/sean/workspace/projects/ironledger/spec/process-release-1-0.md`
- **FILE-004**: `/home/sean/workspace/projects/ironledger/docs/feature-prd.md`
- **FILE-005**: `/home/sean/workspace/projects/ironledger/README.md`
- **FILE-006**: `/home/sean/workspace/projects/ironledger/rebar.config`
- **FILE-007**: `/home/sean/workspace/projects/ironledger/config/sys.config`
- **FILE-008**: `/home/sean/workspace/projects/ironledger/config/vm.args`
- **FILE-009**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/cb_router.erl`
- **FILE-010**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/cb_schema.erl`
- **FILE-011**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/cb_http_errors.erl`
- **FILE-012**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/handlers/cb_savings_products_handler.erl`
- **FILE-013**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/handlers/cb_savings_products_list_handler.erl`
- **FILE-014**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/handlers/cb_loan_products_handler.erl`
- **FILE-015**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/handlers/cb_loans_handler.erl`
- **FILE-016**: `/home/sean/workspace/projects/ironledger/apps/cb_integration/src/handlers/cb_loan_repayments_handler.erl`
- **FILE-017**: `/home/sean/workspace/projects/ironledger/apps/cb_savings_products/include/savings_product.hrl`
- **FILE-018**: `/home/sean/workspace/projects/ironledger/apps/cb_savings_products/src/cb_savings_products.erl`
- **FILE-019**: `/home/sean/workspace/projects/ironledger/apps/cb_loans/include/loan.hrl`
- **FILE-020**: `/home/sean/workspace/projects/ironledger/apps/cb_loans/src/cb_loan_products.erl`
- **FILE-021**: `/home/sean/workspace/projects/ironledger/apps/cb_loans/src/cb_loan_accounts.erl`
- **FILE-022**: `/home/sean/workspace/projects/ironledger/apps/cb_loans/src/cb_loan_calculations.erl`
- **FILE-023**: `/home/sean/workspace/projects/ironledger/apps/cb_loans/src/cb_loan_repayments.erl`
- **FILE-024**: `/home/sean/workspace/projects/ironledger/apps/cb_interest/include/cb_interest.hrl`
- **FILE-025**: `/home/sean/workspace/projects/ironledger/apps/cb_interest/src/cb_interest.erl`
- **FILE-026**: `/home/sean/workspace/projects/ironledger/apps/cb_interest/src/cb_interest_accrual.erl`
- **FILE-027**: `/home/sean/workspace/projects/ironledger/apps/cb_interest/src/cb_interest_posting.erl`
- **FILE-028**: `/home/sean/workspace/projects/ironledger/apps/cb_dashboard/app.go`
- **FILE-029**: `/home/sean/workspace/projects/ironledger/apps/cb_dashboard/api.go`
- **FILE-030**: `/home/sean/workspace/projects/ironledger/apps/cb_dashboard/views.go`
- **FILE-031**: `/home/sean/workspace/projects/ironledger/docker-compose.yml`
- **FILE-032**: `/home/sean/workspace/projects/ironledger/Dockerfile`

## 6. Testing

- **TEST-001**: `rebar3 compile` succeeds after adding product, loan, and interest startup wiring.
- **TEST-002**: `rebar3 ct` covers the restored HTTP route surface and the underlying domain workflows for savings products, loan products, loans, repayments, and interest posting.
- **TEST-003**: `rebar3 dialyzer` remains clean after the rate-type migration and route restoration.
- **TEST-004**: `rebar3 proper` executes non-zero properties covering rate arithmetic, payment allocation, and overflow boundaries.
- **TEST-005**: `GOOS=js GOARCH=wasm go vet ./...` succeeds after dashboard expansion.
- **TEST-006**: `GOOS=js GOARCH=wasm go build -o dist/ironledger.wasm .` succeeds with `dist/wasm_exec.js` packaged alongside the artifact.
- **TEST-007**: API tests confirm savings product, loan product, loan, approval, disbursement, and repayment routes return mapped success and error responses against a running system.
- **TEST-008**: Browser automation confirms the dashboard can perform the full 1.0 happy path without hidden shell steps.
- **TEST-009**: `docker compose up --build` from a clean checkout results in healthy services and successful smoke requests to the documented dashboard and API URLs.

## 7. Risks & Assumptions

- **RISK-001**: The float-to-basis-point migration touches multiple apps and will likely break existing product, loan, and interest tests until the full contract is updated together.
- **RISK-002**: Loan disbursement and repayment are currently shallow state transitions; integrating them with the ledger or payments core may require additional system-account or workflow design.
- **RISK-003**: Interest posting currently depends on synthetic account IDs that do not exist in a fresh runtime. If this is not resolved explicitly, compose deployment will still fail on real interest posting flows.
- **RISK-004**: The dashboard currently has no product or loan views, so UI work is large enough to rival the backend work.
- **RISK-005**: Adding real PropEr coverage may uncover arithmetic or validation defects that are currently masked by the absence of executed properties.
- **RISK-006**: Mnesia persistence behavior in containers must be decided early or documentation and smoke tests will drift.
- **ASSUMPTION-001**: A single-node local deployment remains sufficient for 1.0.
- **ASSUMPTION-002**: Authentication remains out of scope for 1.0, so the dashboard can operate directly against the local API.
- **ASSUMPTION-003**: The backend may provision internal system accounts during startup if that is the simplest valid way to support interest and loan offset postings.

## 8. Related Specifications / Further Reading

- [IronLedger 1.0 Release Specification](/home/sean/workspace/projects/ironledger/spec/process-release-1-0.md)
- [Feature PRD](/home/sean/workspace/projects/ironledger/docs/feature-prd.md)
- [Architecture](/home/sean/workspace/projects/ironledger/docs/architecture.md)
- [Testing Strategy](/home/sean/workspace/projects/ironledger/docs/testing-strategy.md)
- [API Contract](/home/sean/workspace/projects/ironledger/docs/api-contract.yaml)
