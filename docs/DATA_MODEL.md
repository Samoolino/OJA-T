# OJA-T Data Model

The following entities form the first implementation contract. Names are intentionally independent from Spree internals so the allocation domain can evolve without coupling financial rules to checkout code.

## PlanOwner

Represents the organization/person responsible for a Plan.

- id
- account/reference to platform identity
- name
- status
- created_at
- updated_at

## Plan

The primary subscription/funding container.

- id
- plan_owner_id
- name
- description
- currency
- funding_target
- funded_amount (derived/reconciled; ledger remains authoritative)
- allocation_mode
- spending_mode
- starts_at
- ends_at
- status
- created_at
- updated_at

## PlanSubscription

Defines recurring funding of a Plan.

- id
- plan_id
- interval
- amount
- currency
- next_billing_at
- status
- external_subscription_reference
- created_at
- updated_at

## PlanFunding

Records a funding event associated with a Plan.

- id
- plan_id
- amount
- currency
- external_payment_reference
- status
- funded_at
- created_at

## Receiver

The beneficiary/authorized user of allocations.

- id
- platform/customer reference
- status
- created_at
- updated_at

A Receiver may have many PlanAllocations.

## PlanAllocation

The entitlement issued from a Plan to a Receiver.

- id
- plan_id
- receiver_id
- original_amount
- consumed_amount
- reserved_amount
- currency
- starts_at
- expires_at
- status
- allocation_reference
- created_at
- updated_at

The available amount is computed from authoritative ledger/reservation state rather than trusted as a mutable balance.

## AllocationRule

Defines where and how an allocation may be consumed.

Examples:

- allowed product/category
- allowed vendor
- maximum transaction amount
- period limit
- geographic constraint
- start/end time
- rollover policy
- priority

## AllocationLedgerEntry

Append-only accounting/event record.

- id
- allocation_id
- entry_type
- amount
- currency
- reference_type
- reference_id
- idempotency_key
- balance_snapshot (optional reporting aid, never the sole source of truth)
- created_at

Suggested entry types:

- funding
- allocation_issued
- reservation
- reservation_release
- consumption
- refund
- reversal
- adjustment
- expiry

## AllocationReservation

Temporary hold during checkout.

- id
- allocation_id
- order_id (nullable until order creation)
- amount
- currency
- status
- expires_at
- idempotency_key
- created_at
- released_at
- consumed_at

## Settlement

Vendor-facing settlement record.

- id
- order_id
- vendor_reference
- gross_amount
- platform_fee
- net_amount
- currency
- status
- settlement_reference
- settled_at
- created_at

## Relationships

```text
PlanOwner 1 --- N Plan
Plan 1 --- N PlanSubscription
Plan 1 --- N PlanFunding
Plan 1 --- N PlanAllocation
Receiver 1 --- N PlanAllocation
PlanAllocation 1 --- N AllocationRule
PlanAllocation 1 --- N AllocationLedgerEntry
PlanAllocation 1 --- N AllocationReservation
Spree Order 1 --- N Settlement
```

## Important design choice

Do not create a single `receiver.wallet_balance` field as the source of truth. Receivers may have several allocations with different owners, expiry dates, and restrictions. The system must preserve allocation lineage through every reservation, purchase, refund, and settlement.
