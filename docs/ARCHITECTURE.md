# OJA-T Architecture

## 1. System boundary

OJA-T extends Spree Commerce with an allocation domain. Spree remains responsible for catalog, variants, carts, orders, inventory, payments, fulfillment, and vendor commerce. OJA-T adds plan ownership, recurring funding, receiver allocations, eligibility, reservation, ledgering, and allocation-aware settlement.

```text
Plan Owner
   |
   v
Subscription Plan ----> Plan Funding
   |
   v
Plan Allocations <---- Allocation Rules
   |
   v
Receiver (many plans)
   |
   v
Marketplace / Cart
   |
   v
Allocation Eligibility + Reservation
   |
   v
Spree Order / Payment
   |
   +----> Vendor A settlement
   +----> Vendor B settlement
   +----> Vendor C settlement
```

## 2. Actors

### Platform
Operates the marketplace, controls platform configuration, and orchestrates checkout and settlement.

### Plan Owner
Funds and manages a Plan. The owner can configure recurring funding, eligible receivers, spending rules, vendor/product restrictions, allocation limits, and lifecycle dates.

### Receiver
A beneficiary who can receive allocations from one or many Plans. A receiver does not automatically own the underlying Plan funding.

### Vendor
A marketplace seller that lists products and receives settlement after an eligible order is captured/fulfilled according to the settlement policy.

### Plan
A funding and policy container. It is the primary subscription object in OJA-T.

### Allocation
A bounded entitlement derived from a Plan and assigned to a Receiver. Each allocation retains its Plan lineage and rules.

## 3. Money/entitlement lifecycle

```text
Plan subscription
      |
      v
Funding event
      |
      v
Plan funded balance
      |
      v
Allocation issuance
      |
      v
Receiver allocation
      |
      +--> Reservation
      |       |
      |       +--> release on failed/expired checkout
      |       +--> consume on successful order
      |
      v
Allocation ledger
      |
      v
Vendor settlement + platform fees + reconciliation
```

An allocation is not modeled as a generic unrestricted wallet. The ledger is authoritative for balance calculations and audit history.

## 4. Multi-plan checkout

The checkout service must be able to evaluate multiple allocations belonging to the same Receiver. It should:

1. Load active allocations.
2. Filter by product, vendor, category, date, geography, and spending rules.
3. Determine eligible allocation combinations.
4. Reserve the required amount on each allocation.
5. Create the Spree order/payment workflow.
6. Consume reservations only after the payment/order transition is successful.
7. Release reservations on failure, cancellation, or timeout.
8. Create vendor settlement records linked to the order and settlement source.

Example:

```text
Cart total:        NGN 45,000
Plan A available:  NGN 30,000
Plan B available:  NGN 20,000

Reservation:
Plan A             NGN 30,000
Plan B             NGN 15,000
```

## 5. Separation of concerns

Spree answers:

- What was ordered?
- Which vendor supplied it?
- What is the product/variant price?
- What inventory is available?
- What payment/order state exists?
- What fulfillment occurred?

OJA-T answers:

- Who funded the entitlement?
- Which Plan created it?
- Which Receiver can use it?
- What rules apply?
- Which allocation(s) may authorize this order?
- How much has been reserved/consumed?
- Which funding lineage supports the purchase?

## 6. Financial invariants

- Ledger entries are append-only.
- A successful consumption must reference an allocation and an order/line item.
- A reservation cannot exceed available allocation balance.
- A released reservation cannot be consumed.
- A refund/reversal creates a compensating ledger entry rather than mutating historical entries.
- An allocation cannot be consumed after expiry unless an explicit policy allows it.
- Vendor settlement must reconcile to order line totals and platform fees.

## 7. Recommended implementation sequence

1. Bootstrap Spree baseline.
2. Add OJA domain models and migrations.
3. Add ledger and allocation services.
4. Add Plan subscription/funding lifecycle.
5. Add receiver allocation APIs.
6. Add allocation eligibility service.
7. Add allocation-aware checkout/reservation.
8. Add vendor settlement/reconciliation.
9. Add admin/owner/receiver/vendor interfaces.
10. Add automated tests for financial invariants and end-to-end purchase flows.
