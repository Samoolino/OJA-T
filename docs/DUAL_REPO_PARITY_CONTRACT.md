# Dual-Repository Functional Parity Contract

## Decision

**OJa-WA and OJA-T are competitive/parallel implementations of the same OJa-WA product capability.** They must not be treated as a product-layer repository and an execution-layer repository with different functional targets.

Each repository is expected to be able to converge on the same externally observable product and transaction behavior:

- subscription/plan ownership
- funding and funding evidence
- beneficiary/receiver access
- bounded allocation entitlement
- policy and geography controls
- multi-vendor/catalog checkout
- payment evidence and lifecycle
- reservation/consumption/release/reversal
- fulfillment
- vendor settlement
- reconciliation
- audit/idempotency
- institutional production gates

A repository may use a different internal architecture, framework, or implementation strategy, but a missing capability in one repository is a **parity gap**, not an intentional division of responsibility.

## Current re-baseline

The repositories are re-entering implementation from their actual checked-in state as of 2026-09-20.

### OJa-WA

Current state: mature Spree-oriented marketplace implementation with subscription/allocation/wallet/redemption/audit concepts and additional institutional controls already present in the codebase.

Its README still contains earlier scaffold/reintegration language; that language is historical and must not be interpreted as the current acceptance contract.

### OJA-T

Current state: executable Rails transaction/integrity foundation with persistent plan/allocation/ledger/funding/payment-evidence/order-split/fulfillment/settlement/reconciliation boundaries, idempotency, geography authorization, and gated settlement/fulfillment transitions.

CI has not yet been observed as passing for the current head. Therefore this is an implementation-stage claim, not a production-certification claim.

## Shared functional state machine

Both implementations must converge on:

`PLAN -> FUNDING VERIFIED -> ALLOCATION ACTIVE -> AUTHORIZATION -> RESERVATION -> PAYMENT CAPTURE -> CONSUMPTION -> FULFILLMENT -> RECONCILIATION -> SETTLEMENT`

Failure/compensation paths:

`RESERVATION -> RELEASE`

`CONSUMPTION -> REVERSAL/REFUND`

`PAYMENT EVIDENCE MISMATCH -> RECONCILIATION EXCEPTION -> SETTLEMENT BLOCK`

## Shared financial invariant

`available = funded - reserved - consumed + released + reversed`

Required invariants:

1. Available balance never becomes negative.
2. Funding requires verified ingress/evidence.
3. Reservations are idempotent and cannot exceed available balance.
4. Consumption cannot exceed reserved balance.
5. Release cannot exceed reserved balance.
6. Reversal cannot exceed consumed balance.
7. Historical ledger entries are append-only.
8. Provider webhook replay cannot duplicate financial effects.
9. Reconciliation exceptions block settlement.
10. Every money-changing command has idempotency and correlation identifiers.

## Shared privacy/security requirements

- Beneficiary authorization is server-side.
- Public QR/UUID references never contain NIN/BVN.
- KYC assertions are separated from public transaction identifiers.
- Geographic evidence is policy-controlled; GPS telemetry is not automatically cryptographic proof.
- Payment-provider evidence does not become the allocation ledger authority.
- Agents/automation cannot silently activate plans, move funds, bypass KYC/policy, or alter immutable history.

## Production-gate parity

Both repositories use the same acceptance gates:

- **G0 Architecture**
- **G1 Integration contracts**
- **G2 Sandbox certification**
- **G3 Financial integrity/reconciliation**
- **G4 Security/compliance**
- **G5 Production canary**
- **G6 Institutional sign-off**

The current work resumes at the highest gate supported by checked-in evidence; it does not reset either repository to an earlier scaffold stage.

## Implementation rule

When a capability is implemented in one repository, it becomes a parity requirement for the other. Differences are documented as implementation variance, never as different product scope.

The active engineering loop is:

`re-baseline -> parity gap -> implement -> test -> CI -> evidence -> advance gate`

No live payment movement, custody, KYC/AML processing, or production settlement is inferred merely from source-code presence.
