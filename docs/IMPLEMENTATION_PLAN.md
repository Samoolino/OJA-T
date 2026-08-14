# OJA-T Implementation Plan

## Phase 0 — Baseline

- Bootstrap the repository with the selected Spree Commerce baseline.
- Pin the Spree version and Ruby/runtime versions.
- Keep upstream Spree changes isolated from OJA domain code.
- Add CI for tests, linting, security checks, and database migrations.

## Phase 1 — Domain foundation

Implement migrations/models for:

- PlanOwner
- Plan
- PlanSubscription
- PlanFunding
- Receiver
- PlanAllocation
- AllocationRule
- AllocationLedgerEntry
- AllocationReservation
- Settlement

Acceptance criteria:

- One Plan Owner can own many Plans.
- One Receiver can receive allocations from many Plans.
- An allocation always has a Plan and Receiver.
- Ledger records are append-only.
- Currency is explicit on all monetary records.

## Phase 2 — Services

Create service boundaries:

```text
Plans::Create
Plans::Fund
Plans::Subscribe
Plans::Renew
Plans::Suspend
Plans::Expire

Allocations::Issue
Allocations::Reserve
Allocations::Release
Allocations::Consume
Allocations::Refund
Allocations::Reverse

Eligibility::Evaluate
Checkout::AllocationAuthorization
Settlement::Build
Settlement::Reconcile
```

All money-changing operations should be idempotent and transactionally safe.

## Phase 3 — APIs

Initial API surface:

```text
POST /api/v3/plans
GET  /api/v3/plans/:id
POST /api/v3/plans/:id/fund
POST /api/v3/plans/:id/subscribe
POST /api/v3/plans/:id/allocations
GET  /api/v3/plans/:id/allocations

GET  /api/v3/receivers/:id/plans
GET  /api/v3/receivers/:id/allocations
GET  /api/v3/receivers/:id/available-allocation

POST /api/v3/allocations/:id/reserve
POST /api/v3/allocations/:id/release
POST /api/v3/allocations/:id/consume

POST /api/v3/checkout/validate-allocation
POST /api/v3/checkout/allocate

GET  /api/v3/vendors/:id/settlements
GET  /api/v3/plans/:id/settlements
```

Exact routes should follow the conventions of the selected Spree API version once the Spree baseline is installed.

## Phase 4 — Allocation-aware checkout

Implement an authorization service between cart calculation and payment/order completion.

Required sequence:

```text
Cart
  -> identify Receiver
  -> calculate eligible allocations
  -> select allocation combination
  -> reserve
  -> create/authorize Spree order/payment
  -> consume on successful transition
  -> settle vendor(s)
```

Failure path:

```text
payment/order failure
  -> release reservation
  -> leave allocation balance unchanged
```

## Phase 5 — Vendor settlement

Preserve Spree's vendor/order capabilities. Add settlement records that retain:

- order
- vendor
- order line(s)
- gross amount
- platform fee
- net settlement
- allocation/funding lineage
- settlement status

## Phase 6 — Admin surfaces

### Plan Owner

- Plans
- Funding
- Subscription schedule
- Receiver allocation management
- Rules
- Utilization
- Settlement reporting

### Receiver

- My Plans
- Available allocations
- Allocation restrictions
- Transaction history
- Order history

### Vendor

- Catalog
- Orders
- Fulfillment
- Settlement statements

### Platform Admin

- Owners
- Plans
- Receivers
- Vendors
- Funding
- Allocation ledger
- Reconciliation
- Audit events

## Phase 7 — Tests

Minimum test groups:

1. Plan ownership and lifecycle.
2. Subscription renewal/funding.
3. Multiple allocations per receiver.
4. Allocation eligibility.
5. Reservation concurrency.
6. Multi-allocation checkout.
7. Failed payment release.
8. Refund/reversal accounting.
9. Vendor settlement reconciliation.
10. Idempotency and duplicate request protection.
11. Allocation expiry.
12. Audit/ledger integrity.

## Phase 8 — Production hardening

Before real payment processing, add:

- idempotency keys
- authorization boundaries
- audit logging
- encrypted secrets/configuration
- webhook signature verification
- reconciliation jobs
- transaction retry policy
- concurrency controls
- database constraints
- monitoring and alerting
- financial reporting exports

Actual custody, stored-value, payment-provider, KYC/AML, and regulatory requirements must be handled according to the jurisdictions and payment rails used by the deployment.
