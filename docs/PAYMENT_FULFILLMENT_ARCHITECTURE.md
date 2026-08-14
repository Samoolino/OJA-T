# OJA Payment, Funding, Authorization, Fulfillment & Settlement Architecture

## Purpose

This document extends the OJA-T subscription-funded multi-vendor marketplace PR with a complete transaction model. It separates **authorization**, **funding**, **order**, **fulfillment/delivery**, and **vendor settlement** so that biometric/P-256 approval, QR/device scan, plan allocations, coupons, transfers, and other payment methods are not conflated.

## Core principle

A transaction answers five different questions:

1. **Who is authorized to make the purchase?** — Authorization.
2. **What value funds the purchase?** — Funding source.
3. **What was purchased?** — Spree Order/LineItems.
4. **How is the product/service delivered?** — Fulfillment and Delivery.
5. **When/how does the vendor receive settlement?** — Settlement.

The canonical lifecycle is:

```text
DISCOVERY → CART → PAYMENT INTENT → AUTHORIZATION → FUNDING → ORDER
→ FULFILLMENT → DELIVERY → DELIVERY CONFIRMATION → SETTLEMENT
```

## PaymentIntent

`PaymentIntent` is the central transaction orchestration object. It links the receiver, vendor, order, authorization, funding, fulfillment and settlement without making any one of those concepts responsible for the others.

Suggested attributes:

- `payment_intent_id`
- `order_id`
- `receiver_id`
- `vendor_id`
- `amount`
- `currency`
- `funding_source`
- `authorization_method`
- `allocation_ids`
- `delivery_method`
- `status`
- `expires_at`
- `nonce`
- `challenge`

### Funding sources

Supported/anticipated funding sources are explicit values, not authorization methods:

- `plan_allocation`
- `transfer`
- `card`
- `external_payment`

A receiver may use more than one eligible plan allocation for one order.

### Authorization methods

Authorization is independently modeled and can include:

- `biometric_p256`
- `qr_scan`
- `device_confirmation`
- `coupon`
- `payment_link`
- `manual`

A QR code, coupon, biometric approval or device scan is therefore an **authorization/entitlement mechanism**, not automatically the underlying payment rail.

## P-256 / secp256r1 biometric authorization

Biometric approval is implemented as biometric-mediated cryptographic authorization. The biometric is used locally by the customer's authenticator/device to unlock use of a private P-256 credential. OJA verifies the resulting cryptographic signature.

```text
Customer biometric
    ↓
Local authenticator
    ↓
P-256 / secp256r1 private key use
    ↓
Cryptographic signature
    ↓
Vendor device / OJA verification
    ↓
PaymentIntent authorization
```

OJA must not store or receive raw fingerprints, face images, biometric templates, or the private key. The system should store/reference a credential ID and public key as appropriate.

The signed transaction challenge should bind at minimum to:

- payment intent ID
- receiver/credential identity
- vendor ID
- amount
- currency
- allocation selection where applicable
- nonce
- expiry

This prevents replay or transaction substitution.

## Vendor-device transaction

For a vendor POS/device flow:

```text
Vendor device creates PaymentIntent/challenge
        ↓
Customer scans/confirms/authenticates
        ↓
Customer authenticator produces P-256 signature
        ↓
Vendor device/OJA verifies signature
        ↓
Allocation engine authorizes funding
        ↓
Spree order is completed
```

The vendor device should not need access to the customer's biometric data.

## Plan allocation and coupon flows

A plan allocation is a funding source/entitlement. A coupon may be an authorization or entitlement instrument that references a plan/allocation and applicable eligibility rules.

Example:

```text
Plan: Nutrition Benefit
Allocation: ₦20,000
Coupon/QR credential: FOOD-2026-001
        ↓
Validate receiver + plan + allocation + vendor/product eligibility
        ↓
Reserve allocation
        ↓
Complete order
        ↓
Consume allocation
```

## Multi-plan checkout

One receiver can hold allocations from multiple plans. One purchase can consume multiple eligible allocations.

```text
Receiver
 ├── Plan A allocation → ₦40,000
 ├── Plan B allocation → ₦30,000
 └── Plan C allocation → ₦100,000

Order = ₦50,000

Plan A → ₦40,000
Plan B → ₦10,000
```

Each allocation consumption must retain lineage in the OJA ledger and order-allocation linkage.

## Fulfillment and delivery

Payment completion does not equal delivery completion. Fulfillment is a first-class transaction domain.

```text
Spree Order
    ↓
Fulfillment Engine
    ↓
Vendor fulfillment / 3PL / courier / pickup / digital delivery
    ↓
Shipment / Delivery
    ↓
Tracking
    ↓
Proof of Delivery where required
    ↓
Customer
```

Recommended entities:

- `VendorFulfillmentProfile`
- `FulfillmentOrder`
- `Shipment`
- `Delivery`
- `DeliveryEvent`
- `ProofOfDelivery` where applicable

A multi-vendor order may generate multiple fulfillment records and shipments:

```text
OJA Order
 ├── Vendor A → Shipment A → Courier X
 └── Vendor B → Shipment B → Courier Y
```

### Fulfillment profile

Vendor fulfillment configuration should support, as applicable:

- fulfillment mode
- delivery provider
- pickup availability
- delivery regions
- processing time
- delivery SLA
- tracking support
- proof-of-delivery requirement

## Independent status domains

Do not collapse payment, order, fulfillment, delivery and settlement into one status.

```text
Payment:     AUTHORIZED
Order:       CONFIRMED
Fulfillment: PACKED
Delivery:    IN_TRANSIT
Settlement:  HELD
```

Later:

```text
Delivery:    DELIVERED
Settlement:  ELIGIBLE / PROCESSING / SETTLED
```

This allows vendor settlement rules to depend on delivery confirmation when required.

## Vendor-specific settlement

Settlement remains vendor-specific and is driven by the vendor settlement profile.

```text
Vendor
 └── SettlementProfile
      ├── settlement_strategy
      ├── minimum_payout_threshold
      ├── settlement_delay_window
      ├── commission_rate
      ├── currency
      └── payout_destination_reference
```

Strategies include:

- `instant`
- `threshold_batched`
- future delivery-confirmation or manual-review strategies

Settlement state should progress through explicit states such as:

```text
pending_settlement
      ↓
scheduled
      ↓
processing_payout
      ↓
settled
```

Failure paths:

```text
pending_settlement → payout_failed → retry/manual_review
processing_payout → payout_failed
```

A transfer API acceptance must not by itself mark a settlement as `settled`. Gateway webhook confirmation closes the payout lifecycle.

## End-to-end transaction

```text
                    CUSTOMER / RECEIVER
                            │
                 authorization method
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
       P-256             QR/Scan            Coupon
      biometric          Device             /Code
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ↓
                      PAYMENT INTENT
                            │
                 ┌──────────┴──────────┐
                 │                     │
            FUNDING ENGINE       AUTHORIZATION
                 │                     │
       Plan Allocation /         Signature /
       Transfer / Card /         Credential /
       External Payment          Entitlement
                 │                     │
                 └──────────┬──────────┘
                            ↓
                    ALLOCATION ENGINE
                            ↓
                       SPREE ORDER
                            ↓
                     ORDER ALLOCATIONS
                            ↓
                    FULFILLMENT ENGINE
                            ↓
                   SHIPMENT / DELIVERY
                            ↓
                  DELIVERY CONFIRMATION
                            ↓
                    SETTLEMENT ENGINE
                            ↓
                 Vendor-specific routing
                    /         |        \
               Instant    Batched     Delayed
                            ↓
                     PAYMENT GATEWAY
                            ↓
                         WEBHOOK
                            ↓
                     SETTLED / FAILED
```

## Integration sequence for OJA-T

1. Add `PaymentIntent` and authorization/funding abstractions.
2. Connect Spree checkout completion to PaymentIntent finalization.
3. Consume reserved plan allocations only after the order/payment transaction reaches the appropriate successful state.
4. Preserve `OrderAllocation` lineage for every allocation used.
5. Create vendor settlement records from order/vendor splits.
6. Apply vendor-specific settlement strategy and delay/threshold rules.
7. Add fulfillment, shipment and delivery records linked to Spree orders and vendors.
8. Keep payment, order, fulfillment, delivery and settlement states independent.
9. Add P-256/WebAuthn-compatible credential verification as an authorization adapter, not a biometric database.
10. Add end-to-end RSpec coverage for allocation + authorization + order + fulfillment + settlement flows.

## Security and financial invariants

- Never store raw customer biometrics in OJA.
- Never store customer P-256 private keys server-side.
- Bind signatures to transaction-specific challenges, nonce and expiry.
- Prevent authorization replay.
- Use allocation reservations before consumption.
- Keep allocation and settlement ledgers auditable and append-only where appropriate.
- Do not mark settlement paid before asynchronous provider confirmation.
- Keep gateway integrations behind adapters.
- Treat delivery confirmation as separate from payment authorization.
- Preserve vendor, order, allocation and settlement lineage for reconciliation.
