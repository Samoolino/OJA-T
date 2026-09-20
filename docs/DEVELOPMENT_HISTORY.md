# OJA-T Development History

## Historical implementation sequence

The repository evolved through a sequence of feature branches covering the subscription allocation marketplace and its transaction execution layer.

### Subscription/allocation foundation

- `feature/subscription-allocation-core`
- `feature/subscription-allocation-core-v2`
- allocation data model and subscription allocation architecture documentation

### Core implementation branches

- `feature/oja-core`
- `feature/oja-core-actual`
- `feature/oja-core-actual-2`
- `feature/oja-implementation`
- `feature/oja-build` through `feature/oja-build-10`
- `feature/oja-final`, `feature/oja-final-2`, `feature/oja-final-3`

### Payment/settlement execution

- `feature/oja-payment-production-adapters`
- provider-neutral payment boundary
- Stripe adapter/client
- PaymentIntent orchestration
- webhook verification/reconciliation
- allocation reservation/consumption
- order allocation
- vendor settlement and Stripe Connect routing
- fulfillment and delivery-gated settlement
- settlement batching/scheduling/reconciliation
- CI and targeted RSpec coverage

### Main-branch hardening

- payout provider destination correction
- accidental base-provider change reverted
- vendor fulfillment creation boundary
- phased implementation documentation
- manual payment PR-head verification CI

## Consolidation status — 2026-09-20

The `feature/oja-payment-production-adapters` branch is materially ahead of `main` and contains the largest transaction-execution implementation. It is preserved in the institutional consolidation branch while the existing payment-adapter PR remains the review path into `main`.

The consolidation must be reviewed for dependency/lockfile correctness, CI, financial invariants and merge conflicts before the implementation is promoted to `main`.

## Architectural relationship

OJa-WA = product/institutional source of truth.

OJA-T = auxiliary transaction execution implementation.

No external integration is considered production-certified merely because its adapter exists in code.
