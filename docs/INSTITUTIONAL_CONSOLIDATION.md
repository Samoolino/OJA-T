# OJA-T Institutional Consolidation

OJA-T is the auxiliary execution repository for OJa-WA. It implements reusable financial and transaction components against the OJa-WA institutional product contract.

## Included execution domains

- Plan, Plan Owner, Plan Subscription and Plan Funding
- Receiver and Plan Allocation
- Allocation issuance, reservation and consumption
- Allocation ledger entries and order allocation lineage
- Allocation-aware checkout and Spree order completion
- Provider-neutral payment adapter contract
- Stripe payment client/adapter and PaymentIntent orchestration
- Webhook signature verification and idempotent reconciliation boundary
- Vendor settlement profiles and settlement records
- Stripe Connect settlement provider boundary
- Settlement eligibility, routing, batching, scheduling and reconciliation
- Vendor fulfillment creation and delivery confirmation
- Delivery-gated settlement support
- Payment/fulfillment webhooks
- CI and focused model/service/integration specifications

## Institutional extensions to implement next

### Policy engine
Add explicit rule evaluation for:

- vendor
- store/branch
- product/SKU
- category
- geography
- allocation purpose
- expiry
- KYC tier
- delivery method

### Identity boundary
QR and UUID are opaque access references. NIN/BVN are verification inputs and must not be used as client-side secrets. Provider-specific KYC assertions should resolve to an internal receiver identity.

### ERP/commerce adapters
OJA-T should expose adapter contracts rather than retailer-specific business logic for:

- SAP IDoc / NetSuite inventory ingestion
- Shopify
- Nuvemshop
- POS
- Glovo / other 3PL

### Ledger invariant
The allocation ledger remains append-only. Reservations are temporary claims; consumption and release are explicit events. Refunds and reversals create compensating entries.

## Production gate

The presence of a provider adapter or service object does not mean the provider is production-certified. Live credentials, live payout/settlement and enterprise integrations remain disabled until sandbox tests, webhook replay tests, reconciliation, security review, load testing and operational sign-off are complete.
