# OJA Settlement Engine

## Purpose

OJA settlement is vendor-specific. Settlement behavior is determined by an OJA Vendor Settlement Profile rather than global platform payout constants.

The settlement engine sits after Spree order completion and OJA allocation consumption:

```text
Spree Order Complete
        |
        v
Allocation Consumption
        |
        v
Order Allocation / Vendor Settlement
        |
        v
Vendor Settlement Profile
        |
        +-----------------------+
        |                       |
        v                       v
   instant              threshold_batched
        |                       |
        v                       v
 delay-window job        threshold batch job
        |                       |
        +-----------+-----------+
                    v
             Transfer Gateway
                    |
                    v
              Provider/Webhook
                    |
          +---------+---------+
          |                   |
          v                   v
        paid                failed
```

## Vendor settlement profile

`Oja::VendorSettlementProfile` contains vendor-specific settlement policy:

- `settlement_strategy`: `instant` or `threshold_batched`
- `minimum_payout_threshold`: minimum aggregate payout for batch settlement
- `settlement_delay_window`: delay before an instant payout is attempted
- `commission_rate`: vendor-specific platform commission
- `currency`
- `vendor_reference`
- payout destination/reference information as the integration layer requires

The profile is intentionally separate from Spree's commerce/vendor model so the OJA financial policy can evolve without coupling the core commerce model to one payment provider.

## Settlement creation

When an order is completed, the OJA settlement layer creates vendor-specific settlement records from the order's vendor allocations. The settlement record retains gross amount, platform fee, net payout, status and external settlement reference.

The vendor settlement ledger is separate from the receiver allocation ledger. `AllocationLedgerEntry` remains authoritative for Plan Allocation movements; `VendorSettlement` is authoritative for vendor payable/settlement state.

## Routing rules

### Instant

1. Create pending vendor settlement.
2. Calculate vendor-specific commission.
3. Apply the vendor's delay window.
4. Schedule the payout attempt.
5. Transfer through `Oja::Settlement::TransferGateway`.
6. Record the external payout reference.
7. Wait for provider confirmation before marking the settlement paid.

The delay window supports a configurable dispute/refund buffer without pretending that an API acceptance is final settlement.

### Threshold batched

1. Create pending vendor settlements.
2. Leave them payable but unsettled.
3. Scheduled batch processing groups pending settlements by vendor/profile and currency.
4. Calculate the aggregate payable amount.
5. Compare it with the vendor's minimum payout threshold.
6. If below threshold, leave entries pending for a later run.
7. If threshold is met, initiate one aggregate transfer and associate the resulting external reference with the batch entries.

## Reconciliation

Provider webhook events are reconciled through `Oja::Settlement::Reconcile`.

Supported semantic outcomes:

- `transfer.success` / `settlement.success` -> `paid`
- `transfer.failed` / `settlement.failed` -> `failed`

Reconciliation is idempotent: a settlement already in its terminal state is not repeatedly transitioned by duplicate provider events.

## Payment provider boundary

The settlement engine does not directly depend on Paystack, Flutterwave, a bank API, or another provider. `Oja::Settlement::TransferGateway` is the provider adapter boundary.

Provider adapters should implement:

```text
initiate(amount:, currency:, destination:, reference:, metadata:) -> transfer result
```

Provider webhook controllers should verify the provider signature/authenticity before calling reconciliation. Webhook delivery is asynchronous and is the authoritative confirmation of final transfer state.

## Required invariants

1. A vendor payout cannot be marked `paid` merely because a transfer request was accepted.
2. A settlement cannot be paid twice for the same external reference.
3. A threshold batch cannot include settlements from another vendor.
4. A threshold batch cannot mix currencies.
5. Pending entries remain pending when a vendor threshold has not been met.
6. A failed payout remains traceable and retryable/manual-reviewable without losing the original settlement lineage.
7. Vendor settlement state must not mutate the receiver's Plan Allocation balance directly.
8. Every settlement remains traceable to its OJA order allocation and originating Spree order.
9. Vendor commission is resolved from the vendor's settlement profile, not a global constant.
10. All payout operations require an idempotency/reference boundary.

## Test matrix

The PR should cover at minimum:

| Scenario | Expected result |
|---|---|
| Instant vendor, zero delay | payout is scheduled immediately |
| Instant vendor, delay window | payout waits for configured delay |
| Threshold vendor below threshold | no transfer; entries remain pending |
| Threshold vendor reaches threshold | aggregate transfer initiated |
| Two vendors | each vendor is routed independently |
| Two currencies | currencies are not mixed in one batch |
| Provider success webhook | settlement becomes paid |
| Provider failure webhook | settlement becomes failed |
| Duplicate success webhook | no duplicate settlement transition |
| Duplicate payout attempt | blocked by idempotency/reference rules |
| Vendor-specific commission | payout uses profile rate |
| Refund/dispute buffer | settlement remains pending until configured execution time |

## Next integration layer

After settlement routing is validated, connect it end-to-end to Spree checkout:

```text
Cart
 -> allocation eligibility
 -> multi-allocation reservation
 -> Spree order completion
 -> allocation consumption
 -> vendor settlement creation
 -> settlement routing
 -> provider transfer
 -> webhook reconciliation
 -> order/settlement reconciliation
```
