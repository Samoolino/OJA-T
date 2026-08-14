# OJA Production Payment Adapter Contract

## Purpose

PR #2 defines the production payment-rail boundary without changing the validated OJA transaction core.

## Separation of concerns

```text
Authorization
    |
    +-- WebAuthn / secp256r1
    +-- QR / device confirmation
    +-- Coupon / entitlement
    |
    v
PaymentIntent
    |
    +-- plan_allocation
    +-- transfer
    +-- card
    +-- external_payment
    |
    v
Payment Provider Adapter
    |
    v
Provider webhook
    |
    v
Idempotent reconciliation
```

Authorization is not a payment rail. A biometric/P-256 credential authorizes a transaction; the funding source supplies the value.

## PaymentIntent contract

`Oja::PaymentIntent` currently defines the supported funding sources as:

- `plan_allocation`
- `transfer`
- `card`
- `external_payment`

Authorization methods remain independent:

- `biometric_p256`
- `qr_scan`
- `device_confirmation`
- `coupon`
- `payment_link`
- `manual`

The existing authorization service binds a P-256 signature to the PaymentIntent ID, amount, currency, nonce, expiry, and idempotency key. Raw biometric data is not part of the OJA contract.

## Adapter interface

Production adapters should expose a provider-neutral interface equivalent to:

```ruby
PaymentResult = Data.define(
  :accepted,
  :provider_reference,
  :status,
  :raw_metadata
)

adapter.authorize_or_charge(
  payment_intent: payment_intent,
  amount: payment_intent.amount,
  currency: payment_intent.currency,
  idempotency_key: payment_intent.idempotency_key
)
```

The adapter must never mark an OJA settlement as `settled`. Provider acceptance only establishes that the provider accepted the payment/payout request. Final state is closed through authenticated provider webhook reconciliation.

## Idempotency

Every provider request must carry the OJA PaymentIntent idempotency key. A provider reference must be persisted and uniquely associated with the corresponding PaymentIntent/settlement operation.

Retries must be safe: repeating an operation with the same idempotency key must not create a second charge, transfer, or settlement.

## Webhooks

Provider webhooks must be:

1. authenticated using provider-specific signature verification;
2. bound to a provider event ID;
3. persisted once in the webhook event ledger;
4. safe to replay;
5. mapped to the correct OJA PaymentIntent/settlement reference;
6. incapable of bypassing the existing settlement state machine.

The existing webhook event model remains the system's idempotency boundary.

## P-256 / WebAuthn production boundary

The production authenticator layer must store only the minimum credential metadata required to identify a public key/credential. Private keys and biometric material remain on the user's authenticator/device.

The server verifies a transaction-bound challenge/signature. The credential reference must not be treated as a payment credential by itself.

## Implementation order

1. Provider-neutral adapter interface and result object.
2. Provider configuration and secret boundary.
3. Card adapter.
4. Bank-transfer adapter.
5. External payment adapter.
6. PaymentIntent execution orchestration.
7. WebAuthn/P-256 credential registration and challenge verification.
8. Provider-specific signed webhook verification.
9. Idempotent reconciliation.
10. Failure/retry tests and full CI.

## Non-goals for PR #2

- Do not rewrite Spree checkout.
- Do not store raw biometrics.
- Do not allow vendors to receive biometric credentials.
- Do not make provider acceptance equivalent to settlement.
- Do not replace the allocation ledger with a mutable wallet balance.
