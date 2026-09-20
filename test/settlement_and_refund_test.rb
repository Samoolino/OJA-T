require_relative "test_helper"

class SettlementAndRefundTest < ActiveSupport::TestCase
  setup do
    @plan = Oja::Plan.create!(plan_owner_id: 1, name: "Settlement Plan", currency: "NGN", funding_target_minor: 100_000, status: "active")
    @allocation = Oja::PlanAllocation.create!(plan: @plan, beneficiary_id: "beneficiary-1", currency: "NGN", geo_policy: { "country_code" => "NG" })
    Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 50_000, currency: "NGN",
      source_type: "test_funding", source_reference: "settlement-fund",
      provider: "sandbox", status: "verified",
      idempotency_key: "fund:settlement", correlation_id: "corr:settlement"
    )
    Oja::Allocation::Reservation.call(
      allocation: @allocation, amount_minor: 12_500, beneficiary_id: "beneficiary-1",
      idempotency_key: "reserve:settlement", correlation_id: "corr:settlement",
      context: { "country_code" => "NG" }
    )
    @split = Oja::OrderSplit.create!(
      order_reference: "order-settle", cart_reference: "cart-settle", vendor_id: 10, vendor_store_id: 20,
      currency: "NGN", amount_minor: 12_500, status: "AUTHORIZED", fulfillment_status: "PENDING",
      correlation_id: "corr:settlement", line_items: [{ "id" => "sku", "amount_minor" => 12_500 }]
    )
    result = Oja::Payment::CaptureOrderSplit.call(
      order_id: 2001, split: @split, allocation: @allocation, beneficiary_id: "beneficiary-1",
      amount_minor: 12_500, currency: "NGN", provider: "sandbox", provider_event_id: "evt-settle",
      payment_reference: "pay-settle", correlation_id: "corr-settle", idempotency_key: "consume:settle",
      payload: { "amount_minor" => 12_500, "currency" => "NGN" }, fulfillment_mode: "delivery",
      fulfillment_idempotency_key: "fulfill:settle", settlement_idempotency_key: "settle:settle",
      context: { "country_code" => "NG" }
    )
    @settlement = result.settlement
    @fulfillment = result.fulfillment
  end

  test "settlement remains blocked until fulfillment is confirmed" do
    result = Oja::Settlement::RequestTransfer.call(
      settlement: @settlement, payment_captured: true, vendor_account_ready: true,
      fulfillment_required: true, fulfillment_confirmed: false, reconciliation_status: "MATCHED",
      transfer_idempotency_key: "transfer:settle", correlation_id: "corr-transfer"
    )
    refute result.eligible
    assert_equal "fulfillment_not_confirmed", result.reason
    assert_equal "blocked", @settlement.reload.status
  end

  test "confirmed fulfillment permits sandbox transfer request" do
    Oja::Fulfillment::Transition.call(
      fulfillment: @fulfillment, status: "confirmed", correlation_id: "corr-fulfill", tracking_reference: "TRK-1"
    )
    result = Oja::Settlement::RequestTransfer.call(
      settlement: @settlement, payment_captured: true, vendor_account_ready: true,
      fulfillment_required: true, fulfillment_confirmed: true, reconciliation_status: "MATCHED",
      transfer_idempotency_key: "transfer:settle-2", correlation_id: "corr-transfer-2"
    )
    assert result.eligible
    assert_equal "sandbox_transfer_requested", result.reason
    assert_equal "requested", result.settlement.reload.status
  end

  test "refund reverses consumed balance idempotently" do
    result = Oja::Payment::RefundAllocation.call(
      allocation: @allocation, amount_minor: 12_500,
      idempotency_key: "refund:settle", correlation_id: "corr-refund"
    )
    assert result.refunded
    allocation = @allocation.reload
    assert_equal 0, allocation.consumed_minor
    assert_equal 12_500, allocation.reversed_minor

    replay = Oja::Payment::RefundAllocation.call(
      allocation: @allocation, amount_minor: 12_500,
      idempotency_key: "refund:settle", correlation_id: "corr-refund"
    )
    assert replay.refunded
    assert_equal 1, @allocation.ledger_entries.where(entry_type: "reverse", idempotency_key: "refund:settle").count
  end
end
