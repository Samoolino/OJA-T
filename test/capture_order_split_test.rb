require_relative "test_helper"

class CaptureOrderSplitTest < ActiveSupport::TestCase
  setup do
    @plan = Oja::Plan.create!(plan_owner_id: 1, name: "Order Plan", currency: "NGN", funding_target_minor: 100_000, status: "active")
    @allocation = Oja::PlanAllocation.create!(plan: @plan, beneficiary_id: "beneficiary-1", currency: "NGN", geo_policy: { "country_code" => "NG" })

    Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 50_000, currency: "NGN",
      source_type: "test_funding", source_reference: "order-fund",
      provider: "sandbox", status: "verified",
      idempotency_key: "fund:order", correlation_id: "corr:order"
    )

    Oja::Allocation::Reservation.call(
      allocation: @allocation, amount_minor: 12_500, beneficiary_id: "beneficiary-1",
      idempotency_key: "reserve:order", correlation_id: "corr:order",
      context: { "country_code" => "NG" }
    )

    @split = Oja::OrderSplit.create!(
      order_reference: "order-1", cart_reference: "cart-1",
      vendor_id: 10, vendor_store_id: 20, currency: "NGN", amount_minor: 12_500,
      status: "AUTHORIZED", fulfillment_status: "PENDING", correlation_id: "corr:order",
      line_items: [{ "id" => "sku-1", "amount_minor" => 12_500 }]
    )
  end

  test "matched capture advances split and creates fulfillment and settlement records" do
    result = Oja::Payment::CaptureOrderSplit.call(
      order_id: 1001, split: @split, allocation: @allocation,
      beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-order-1", payment_reference: "pay-order-1",
      correlation_id: "corr-order-1", idempotency_key: "consume:order-1",
      payload: { "amount_minor" => 12_500, "currency" => "NGN" },
      fulfillment_mode: "delivery", fulfillment_idempotency_key: "fulfill:order-1",
      settlement_idempotency_key: "settle:order-1", platform_fee_minor: 500,
      context: { "country_code" => "NG" }
    )

    assert result.captured
    assert_equal "CAPTURED", result.split.reload.status
    assert_equal "pay-order-1", result.split.payment_reference
    assert_equal "pending", result.fulfillment.status
    assert_equal 12_000, result.settlement.net_amount_minor
    assert_equal 1, Oja::OrderFulfillment.where(order_id: 1001).count
    assert_equal 1, Oja::SettlementRecord.where(order_id: 1001).count
  end

  test "reconciliation mismatch does not advance split or create downstream records" do
    result = Oja::Payment::CaptureOrderSplit.call(
      order_id: 1002, split: @split, allocation: @allocation,
      beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-order-2", payment_reference: "pay-order-2",
      correlation_id: "corr-order-2", idempotency_key: "consume:order-2",
      payload: { "amount_minor" => 12_499, "currency" => "NGN" },
      fulfillment_mode: "delivery", fulfillment_idempotency_key: "fulfill:order-2",
      settlement_idempotency_key: "settle:order-2",
      context: { "country_code" => "NG" }
    )

    refute result.captured
    assert_equal "AUTHORIZED", result.split.reload.status
    assert_equal 0, Oja::OrderFulfillment.where(order_id: 1002).count
    assert_equal 0, Oja::SettlementRecord.where(order_id: 1002).count
  end
end
