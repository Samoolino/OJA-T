require_relative "test_helper"

class G2TransactionPathTest < ActiveSupport::TestCase
  setup do
    @plan = Oja::Plan.create!(
      plan_owner_id: 1,
      name: "G2 Certification Plan",
      currency: "NGN",
      funding_target_minor: 100_000,
      status: "active"
    )
    @allocation = Oja::PlanAllocation.create!(
      plan: @plan,
      beneficiary_id: "g2-beneficiary",
      currency: "NGN",
      geo_policy: { "country_code" => "NG" }
    )
  end

  test "certifies verified funding through reservation, capture, fulfillment, settlement and refund" do
    funding = Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 50_000, currency: "NGN",
      source_type: "g2_sponsor", source_reference: "g2-sponsor-1",
      provider: "sandbox", status: "verified",
      idempotency_key: "g2:fund:1", correlation_id: "g2:corr:fund:1"
    )
    assert funding.funded

    replay = Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 50_000, currency: "NGN",
      source_type: "g2_sponsor", source_reference: "g2-sponsor-1",
      provider: "sandbox", status: "verified",
      idempotency_key: "g2:fund:1", correlation_id: "g2:corr:fund:replay"
    )
    assert replay.funded
    assert_equal 50_000, @allocation.reload.funded_minor

    items = [{ id: "g2-sku", amount_minor: 12_500, currency: "NGN", vendor_id: 10, store_id: 20 }]
    authorization = Oja::Checkout::AuthorizeAndReserve.call(
      allocation: @allocation,
      beneficiary_id: "g2-beneficiary",
      line_items: items,
      currency: "NGN",
      idempotency_key: "g2:reserve:1",
      correlation_id: "g2:corr:reserve:1",
      context: { "country_code" => "NG" }
    )
    assert authorization.reserved

    split = Oja::OrderSplit.create!(
      order_reference: "g2-order-1", cart_reference: "g2-cart-1",
      vendor_id: 10, vendor_store_id: 20, currency: "NGN", amount_minor: 12_500,
      status: "AUTHORIZED", fulfillment_status: "PENDING",
      correlation_id: "g2:corr:order:1", line_items: items
    )

    capture = Oja::Payment::CaptureOrderSplit.call(
      order_id: 5001, split: split, allocation: @allocation,
      beneficiary_id: "g2-beneficiary", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "g2:event:1", payment_reference: "g2:pay:1",
      correlation_id: "g2:corr:capture:1", idempotency_key: "g2:consume:1",
      payload: { "amount_minor" => 12_500, "currency" => "NGN" },
      fulfillment_mode: "delivery",
      fulfillment_idempotency_key: "g2:fulfill:1",
      settlement_idempotency_key: "g2:settle:1",
      platform_fee_minor: 500,
      context: { "country_code" => "NG" }
    )
    assert capture.captured
    assert_equal "CAPTURED", capture.split.reload.status
    assert_equal "pending", capture.fulfillment.status

    blocked = Oja::Settlement::RequestTransfer.call(
      settlement: capture.settlement, payment_captured: true,
      vendor_account_ready: true, fulfillment_required: true,
      fulfillment_confirmed: false, reconciliation_status: "MATCHED",
      transfer_idempotency_key: "g2:transfer:blocked",
      correlation_id: "g2:corr:transfer:blocked"
    )
    refute blocked.eligible
    assert_equal "blocked", capture.settlement.reload.status

    Oja::Fulfillment::Transition.call(
      fulfillment: capture.fulfillment,
      status: "confirmed",
      correlation_id: "g2:corr:fulfill:confirmed",
      tracking_reference: "G2-TRACK-1"
    )

    transfer = Oja::Settlement::RequestTransfer.call(
      settlement: capture.settlement, payment_captured: true,
      vendor_account_ready: true, fulfillment_required: true,
      fulfillment_confirmed: true, reconciliation_status: "MATCHED",
      transfer_idempotency_key: "g2:transfer:1",
      correlation_id: "g2:corr:transfer:1"
    )
    assert transfer.eligible
    assert_equal "requested", transfer.settlement.reload.status

    refund = Oja::Payment::RefundAllocation.call(
      allocation: @allocation, amount_minor: 12_500,
      idempotency_key: "g2:refund:1", correlation_id: "g2:corr:refund:1"
    )
    assert refund.refunded

    final = @allocation.reload
    assert_equal 0, final.consumed_minor
    assert_equal 12_500, final.reversed_minor
  end

  test "provider currency mismatch never consumes the reserved balance" do
    Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 20_000, currency: "NGN",
      source_type: "g2_sponsor", source_reference: "g2-sponsor-2",
      provider: "sandbox", status: "verified",
      idempotency_key: "g2:fund:2", correlation_id: "g2:corr:fund:2"
    )
    Oja::Allocation::Reservation.call(
      allocation: @allocation, amount_minor: 10_000, beneficiary_id: "g2-beneficiary",
      idempotency_key: "g2:reserve:2", correlation_id: "g2:corr:reserve:2",
      context: { "country_code" => "NG" }
    )

    result = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "g2-beneficiary",
      amount_minor: 10_000, currency: "NGN", provider: "sandbox",
      provider_event_id: "g2:event:2", payment_reference: "g2:pay:2",
      order_reference: "g2-order-2", correlation_id: "g2:corr:capture:2",
      idempotency_key: "g2:consume:2",
      payload: { "amount_minor" => 10_000, "currency" => "USD" },
      context: { "country_code" => "NG" }
    )

    refute result.captured
    assert_equal 0, @allocation.reload.consumed_minor
    assert_equal 10_000, @allocation.reserved_minor
  end
end
