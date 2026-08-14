# CI Lifecycle Validation Marker

This marker exists to trigger CI against the current OJA-T PR head after the end-to-end transaction lifecycle test was extended.

Validation scope:

- multi-plan allocation consumption
- PaymentIntent authorization
- Spree order lineage
- multi-vendor fulfillment
- delivery confirmation
- vendor settlement routing
- settlement reconciliation
