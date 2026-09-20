# OJA-T Institutional Execution Contract

OJA-T is the execution-oriented repository for the OJa allocation marketplace. Financial authority is confined to explicit, auditable operations.

## Canonical flow
Sponsor/Plan Owner funding ingress -> Plan -> Allocation -> Beneficiary authorization -> Exact basket evaluation -> Reservation -> Payment evidence -> Capture -> Consumption -> Fulfillment -> Settlement eligibility -> Provider transfer -> Reconciliation.

## Non-negotiable rules
- No positive allocation balance without a funding source/evidence.
- Ledger history is append-only.
- Every money-changing operation requires an idempotency key and correlation ID.
- Client-supplied beneficiary identity is never trusted without server-side authorization.
- NIN/BVN never appears in QR payloads, public UUIDs, or payment metadata.
- GPS coordinates are telemetry; geographic authorization requires canonical policy/evidence.
- Payment-provider status is evidence, not allocation authority.
- Settlement cannot execute until eligibility and reconciliation gates pass.
- Refunds/reversals are compensating entries.
- Provider adapters are execution boundaries.

## Financial invariant
available = funded - reserved - consumed + released + reversed

## Production gates
G0 architecture -> G1 integration contracts -> G2 sandbox certification -> G3 financial integrity/reconciliation -> G4 security/compliance -> G5 production canary -> G6 institutional sign-off.
