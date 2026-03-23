---
title: IronLedger 1.0 Release Checklist
version: 1.0
date_created: 2026-03-22
last_updated: 2026-03-22
owner: Sean
tags: [release, checklist, validation, docker, dashboard]
---

# Introduction

This checklist records the release-candidate validation evidence for IronLedger 1.0.
It is intended to answer one question: can a user pull the repository, run the
documented commands, and get a working Dockerized backend and dashboard with the
full 1.0 feature set?

Current assessment as of 2026-03-22: release candidate, pending final signoff.

## 1. Release Scope Check

Required 1.0 workflows:

- Party management
- Account management
- Transfers, deposits, withdrawals, reversals
- Transaction and ledger inquiry
- Savings product creation and listing
- Loan product creation and listing
- Loan creation, approval, disbursement, detail viewing, and repayment
- Docker Compose startup with working dashboard and API

Status:

- Backend runtime for the full 1.0 app set: pass
- Dashboard coverage for the full 1.0 happy path: pass
- Docker Compose deployment: pass

## 2. Validation Matrix

Validation run date: 2026-03-22

| Check | Command | Result |
|---|---|---|
| Erlang compile | `rebar3 compile` | Pass |
| Common Test | `rebar3 ct` | Pass, `All 111 tests passed.` |
| Dialyzer | `rebar3 dialyzer` | Pass |
| PropEr | `rebar3 proper --numtests 100` | Pass, `8/8 properties passed` |
| Dashboard vet | `cd apps/cb_dashboard && GOOS=js GOARCH=wasm go vet ./...` | Pass |
| Dashboard Wasm build | `cd apps/cb_dashboard && GOOS=js GOARCH=wasm go build -o dist/ironledger.wasm .` | Pass |
| API image build | `docker compose build api` | Pass |
| Dashboard image build | `docker compose build dashboard` | Pass |
| Compose startup | `docker compose up -d` | Pass |
| Dashboard browser E2E | `npm install && npx playwright install chromium && npm run test:e2e` | Pass, `Dashboard E2E flow passed` |

## 3. Runtime Evidence

Validated local URLs:

- Dashboard: `http://localhost:8080`
- API base: `http://localhost:8081/api/v1`
- Health endpoint: `http://localhost:8081/health`

Validated runtime conditions:

- `docker compose ps` showed both `api` and `dashboard` running
- API health returned HTTP 200 with `{"status":"ok"}`
- Dashboard served `index.html`, `wasm_exec.js`, and `ironledger.wasm`
- The compose stack used a named volume for Mnesia persistence

## 4. Business Flow Evidence

Validated API smoke flow against the compose stack:

1. Create party
2. Create account
3. Create savings product
4. Create loan product
5. Create loan
6. Approve loan
7. Disburse loan
8. Record repayment

Validated browser E2E flow against the compose stack:

1. Navigate to dashboard
2. Create customer
3. Create account
4. Create savings product
5. Create loan product
6. Create loan
7. Approve loan
8. Disburse loan
9. Record repayment
10. Verify refreshed state in the UI

## 5. Key Fixes Landed During Release Prep

- Added Docker packaging assets for API and dashboard
- Removed stale `lager_transform` from `rebar.config` so clean release builds succeed
- Added missing OTP `uuid` runtime dependencies in app resource files
- Restored and wired savings, loan, and interest runtime startup
- Added PropEr coverage for payments, interest, and loan calculations
- Added dashboard support for products and loans
- Added dashboard browser automation
- Fixed Wasm form parsing bugs caused by reading numeric input values as JavaScript ints
- Fixed loan repayment response semantics so repayment `status` is repayment-specific and `loan_status` is returned separately

## 6. Remaining Signoff Items

Items still desirable before tagging 1.0:

- Review the release checklist and README as a final editorial pass
- Decide whether to automate this exact matrix in CI
- Tag the release from a clean, reviewed tree

These are signoff and delivery tasks, not known feature-completeness blockers.

## 7. Release Recommendation

Recommendation: proceed as a release candidate.

Rationale:

- The packaged runtime and dashboard now satisfy the stated 1.0 scope
- The quality gates are green
- The browser-level happy path is automated and passing
- No known startup, schema, or route wiring gaps remain in the default Docker deployment
