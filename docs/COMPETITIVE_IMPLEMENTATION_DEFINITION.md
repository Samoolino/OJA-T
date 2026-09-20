# Competitive Implementation Definition

## Two implementations, one functional target

OJa-WA and OJA-T are deliberately maintained as **competitive implementations of the same OJa-WA product and execution system**.

### Implementation A — OJa-WA

OJa-WA is a **Spree open-source rebuilt/extended implementation**. It uses Spree Commerce and its multi-vendor primitives as the commerce substrate, then rebuilds/extends the OJa domain over that foundation.

Relevant existing areas include subscription plans, plan allocations, coupon payouts, wallets, redemptions, vendor/vendor-user structures, commissions, and allocation audit.

### Implementation B — OJA-T

OJA-T is an **independently structured Rails implementation of the same target**, with an institutional transaction/integrity foundation rather than relying on Spree's domain model.

It implements equivalent target capabilities through Oja-specific records and services for funding, allocation, financial ledgering, payment evidence, checkout, fulfillment, reconciliation, settlement and idempotency.

## What “competitive” means

Competitive does not mean incompatible.

Both repositories must be able to satisfy the same acceptance contract:

`Plan -> Subscription/Eligibility -> Funding -> Beneficiary/Receiver -> Allocation -> Policy -> Checkout -> Reservation -> Payment -> Consumption -> Fulfillment -> Reconciliation -> Settlement`

with compensation paths for failure, release, refund and reversal.

Internal implementation may differ:

`OJa-WA = Spree substrate + OJa domain`

`OJA-T = Oja transaction/domain substrate`

but externally observable functionality and financial integrity must converge.

## Production implementation status

As of 2026-09-20, the work is **not at live production payment/settlement execution**.

The current engagement is the transition from architectural/domain implementation into **integration and verification of the transaction path**.

Current gate position:

- G0 Architecture: implemented baseline
- G1 Integration contracts: implemented baseline
- G2 Sandbox certification: **in progress / not certified**
- G3 Financial integrity & reconciliation: **implementation in progress; verification pending**
- G4 Security/compliance: foundation implemented; certification pending
- G5 Production canary: not started
- G6 Institutional sign-off: not started

The current production work therefore means **production-readiness implementation**, not live production execution.

## Re-engagement point

Do not restart from Phase 0 or the historical Spree scaffold.

Resume from the checked-in implementation baseline and close the remaining parity/integration gaps.

### Immediate production-readiness sequence

1. Runtime and migration verification.
2. End-to-end transaction orchestration.
3. Payment lifecycle state machine.
4. Reservation/consume/release/reversal integration.
5. Reconciliation-driven settlement gating.
6. Sandbox provider certification.
7. Security/compliance evidence.
8. Canary preparation.
9. Production canary only after gates are satisfied.
