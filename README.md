# OJA-T

OJA-T is a subscription-funded, multi-vendor marketplace built on top of Spree Commerce primitives.

## Commercial model

**Plan Owner → Subscription Plan → Funding → Allocation → Receiver → Marketplace → Vendor Settlement**

The Plan is the primary funding and allocation object. A Receiver can receive allocations from multiple Plans. Vendors remain marketplace sellers and receive settlement for eligible products purchased by Receivers.

## Design principles

1. Plans, not products, are the primary commercial funding object.
2. A Plan Owner funds and manages Plans.
3. Receivers consume allocations and may hold multiple allocations from multiple Plans.
4. Allocations are entitlement records with explicit rules; they are not automatically treated as unrestricted cash wallets.
5. Every allocation movement is recorded in an immutable ledger.
6. Checkout must authorize eligible allocation(s) before an order is completed.
7. A purchase may consume more than one allocation.
8. Vendor settlement is independent of who funded the Receiver's allocation.
9. Spree commerce primitives should be extended rather than rewritten.

## Spree baseline

OJA-T targets Spree Commerce 5.6.x. The upstream Spree project provides the commerce core, REST APIs, TypeScript SDK, channels, checkout, payments, inventory, and marketplace-oriented primitives that OJA-T will extend.

## Initial domain modules

- Plan Owner
- Subscription Plan
- Plan Subscription
- Plan Funding
- Receiver
- Plan Allocation
- Allocation Rule
- Allocation Ledger
- Allocation Reservation
- Allocation Transaction
- Vendor/Product Eligibility
- Allocation-aware Checkout
- Vendor Settlement

See `docs/ARCHITECTURE.md` and `docs/DATA_MODEL.md` for the implementation contract.
