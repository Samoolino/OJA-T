# OJA-T Continuous Development State

## Operating decision

OJA-T is now the sole active continuous-development repository for the OJa-T product. OJa-WA remains a historical/competitive parity reference only; new implementation work is not scheduled there unless an explicit parity audit requires it.

## Continuation rule

Every implementation request resumes from the highest gate supported by checked-in code and passing CI evidence.

`inspect -> classify -> verify evidence -> if complete, mark IMPLEMENTED -> advance -> implement first incomplete gate -> test -> CI -> record evidence`

A request to "Proceed to Implementation" must not repeat an already-certified implementation. If the requested step is already implemented and its acceptance evidence is current, the response is **ALREADY IMPLEMENTED — ADVANCE TO [next gate]** and execution continues at the next incomplete gate.

Implementation presence alone is never certification. A gate is complete only when its required tests and CI evidence pass for the relevant repository head.

## Production gates

- G0 — Architecture and domain boundaries
- G1 — Integration contracts
- G2 — Sandbox transaction certification
- G3 — Financial integrity and reconciliation hardening
- G4 — Security, privacy, geography and compliance
- G5 — Production canary readiness
- G6 — Institutional production sign-off

## Current OJA-T state

### G0 — COMPLETE
Architecture and persistent transaction boundaries are implemented.

### G1 — COMPLETE
Integration contracts, idempotency, evidence and provider-boundary protections are implemented and covered by the repository integrity workflow.

### G2 — IMPLEMENTED / CI-VERIFIED
The G2 transaction path and required test presence are implemented. The repository's latest observed integrity run on `main` is successful at commit `da9bf3eb97de6e05380552ab8ac31cc6cf7969c5` (run #90). The workflow completed dependency installation, syntax checks, database preparation, tests, and institutional-contract checks successfully.

This is the highest currently supported production gate. It does not imply live payment movement, custody, or production settlement.

### G3 — NEXT IMPLEMENTATION GATE
Start financial-integrity/reconciliation hardening from the already implemented G2 baseline. Priority order:

1. ledger invariant enforcement and violation detection;
2. provider-event replay/concurrency guarantees;
3. reconciliation exception lifecycle and settlement blocking;
4. settlement-transfer idempotency and retry evidence;
5. immutable historical-ledger protections;
6. failure/reversal/refund boundedness;
7. CI evidence for every invariant and negative path.

### G4 — BLOCKED BY G3
Do not advance merely because security-related code exists. Require evidence for authorization, privacy, geography, auditability, webhook authenticity and agent/action boundaries.

### G5/G6 — BLOCKED
Require successful prior gates and explicit operational/institutional evidence.

## Functional state machine

`PLAN -> FUNDING VERIFIED -> ALLOCATION ACTIVE -> AUTHORIZATION -> RESERVATION -> PAYMENT CAPTURE -> CONSUMPTION -> FULFILLMENT -> RECONCILIATION -> SETTLEMENT`

Compensation paths:

`RESERVATION -> RELEASE`

`CONSUMPTION -> REVERSAL/REFUND`

`PAYMENT EVIDENCE MISMATCH -> RECONCILIATION EXCEPTION -> SETTLEMENT BLOCK`

## Product/architecture clarity

OJA-T is not being reduced to a payment processor. The product target remains the complete marketplace/institutional transaction capability: plans, funding, beneficiaries, allocation, geography/policy controls, catalog/checkout, payment evidence, order splitting, fulfillment, reconciliation, settlement, audit and idempotency.

Internal architecture may evolve independently of OJa-WA. External product and transaction contracts are the parity target.

## Geography and location rule

Geographic classification is policy/domain data; coordinates are evidence used by policy evaluation and are not automatically treated as cryptographic proof. Store/derive location evidence separately from public identifiers, and do not expose NIN/BVN or equivalent identity data through public QR/UUID references.

## Evidence rule

For each gate record:

- implementation commit;
- relevant tests;
- CI run and conclusion;
- remaining exceptions;
- next gate.

If a gate is already complete, implementation calls advance without reimplementing it.
