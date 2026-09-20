# OJA-T

OJA-T is the execution-oriented engineering repository for the OJa subscription-funded, multi-vendor allocation marketplace.

## Scope

The repository carries the operational contracts and execution boundaries for:

Plan Owner -> Plan -> Funding ingress -> Allocation -> Beneficiary authorization -> Policy-aware checkout -> Payment evidence -> Consumption -> Fulfillment -> Vendor settlement -> Reconciliation.

Allocations are bounded entitlements, not unrestricted wallets.

## Financial authority

The authoritative invariant is:

available = funded - reserved - consumed + released + reversed

Positive funding requires verified funding ingress/evidence. Ledger history is append-only, money-changing operations are idempotent, and reconciliation exceptions block settlement.

## Security boundaries

- Beneficiary authorization is server-side; client allocation IDs are not proof of entitlement.
- NIN/BVN must never be embedded in QR/public UUID/payment metadata.
- Geographic authorization uses normalized policy and evidence. GPS is telemetry, not cryptographic proof.
- Provider webhooks are verified evidence and must be idempotently ingested.
- Provider adapters are execution boundaries; they do not become the allocation ledger.
- Settlement execution remains gated by payment capture, connected-account readiness, fulfillment requirements, reconciliation, and transfer idempotency.

## Repository layout

- `app/services/oja/financial` — financial invariants.
- `app/services/oja/allocation` — allocation authorization boundary.
- `app/services/oja/geography` — geography policy boundary.
- `app/services/oja/fulfillment` — fulfillment integration boundary.
- `app/services/oja/settlement` — settlement eligibility and provider boundary.
- `docs/` — institutional contracts, architecture, data model, and implementation plan.
- `.github/workflows/` — repository integrity and verification workflows.

## Production gates

G0 Architecture -> G1 Integration contracts -> G2 Sandbox certification -> G3 Financial integrity/reconciliation -> G4 Security/compliance -> G5 Production canary -> G6 Institutional sign-off.

Source code does not by itself activate live payment movement, stored-value custody, KYC processing, or provider payouts.

See:
- docs/INSTITUTIONAL_EXECUTION_CONTRACT.md
- docs/FINANCIAL_INTEGRITY.md
- docs/GEOGRAPHY_AND_LOCATION_POLICY.md
- docs/ARCHITECTURE.md
- docs/DATA_MODEL.md
- docs/IMPLEMENTATION_PLAN.md
