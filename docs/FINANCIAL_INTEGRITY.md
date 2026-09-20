# Financial Integrity

Allocations are bounded entitlements, not unrestricted wallets. Authoritative state is the immutable ledger plus reservation/consumption state.

## Balance equation
available = funded - reserved - consumed + released + reversed

## Controls
1. Funding references an external or platform-controlled funding ingress.
2. Reservation is atomic and idempotent.
3. Consumption cannot exceed an active reservation.
4. Release cannot exceed reserved value.
5. Reversal cannot exceed previously consumed value.
6. Duplicate provider webhooks cannot create duplicate financial effects.
7. Every financial mutation carries operation, idempotency and correlation identifiers.
8. Refunds never rewrite historical entries.
9. Reconciliation exceptions block settlement.

A no-source allocation may exist as funded_minor = 0, but positive funding requires verified funding evidence.
