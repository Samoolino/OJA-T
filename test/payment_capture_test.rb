require_relative "test_helper"

class PaymentCaptureTest < ActiveSupport::TestCase
  setup do
    @plan = Oja::Plan.create!(plan_owner_id: 1, name: "Capture Plan", currency: "NGN", funding_target_minor: 100_000, status: "active")
    @allocation = Oja::PlanAllocation.create!(plan: @plan, beneficiary_id: "beneficiary-1", currency: "NGN", geo_policy: { "country_code" => "NG" })
    Oja::Funding::Issue.call(
      allocation: @allocation, amount_minor: 50_000, currency: "NGN",
      source_type: "test_funding", source_reference: "capture-fund",
      provider: "sandbox", status: "verified",
      idempotency_key: "fund:capture", correlation_id: "corr:capture"
    )
    Oja::Allocation::Reservation.call(
      allocation: @allocation, amount_minor: 12_500, beneficiary_id: "beneficiary-1",
      idempotency_key: "reserve:capture", correlation_id: "corr:capture",
      context: { "country_code" => "NG" }
    )
  end

  test "capture requires matched payment evidence and consumes reservation" do
    result = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-capture-1", payment_reference: "pay-capture-1",
      order_reference: "order-capture-1", correlation_id: "corr-capture-1",
      idempotency_key: "consume:capture-1", payload: { "amount_minor" => 12_500, "currency" => "NGN" },
      context: { "country_code" => "NG" }
    )

    assert result.captured
    assert_equal 0, @allocation.reload.reserved_minor
    assert_equal 12_500, @allocation.consumed_minor
  end

  test "capture blocks amount mismatch" do
    result = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-capture-2", payment_reference: "pay-capture-2",
      order_reference: "order-capture-2", correlation_id: "corr-capture-2",
      idempotency_key: "consume:capture-2", payload: { "amount_minor" => 12_499, "currency" => "NGN" },
      context: { "country_code" => "NG" }
    )

    refute result.captured
    assert_equal "reconciliation_exception", result.reason
    assert_equal 12_500, @allocation.reload.reserved_minor
    assert_equal 0, @allocation.consumed_minor
  end

  test "capture blocks currency mismatch" do
    result = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-capture-3", payment_reference: "pay-capture-3",
      order_reference: "order-capture-3", correlation_id: "corr-capture-3",
      idempotency_key: "consume:capture-3", payload: { "amount_minor" => 12_500, "currency" => "USD" },
      context: { "country_code" => "NG" }
    )

    refute result.captured
    assert_equal "reconciliation_exception", result.reason
    assert_equal 12_500, @allocation.reload.reserved_minor
    assert_equal 0, @allocation.consumed_minor
  end

  test "same provider event and payload is idempotent" do
    first = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-capture-replay", payment_reference: "pay-replay-1",
      order_reference: "order-replay-1", correlation_id: "corr-replay-1",
      idempotency_key: "consume:replay-1", payload: { "amount_minor" => 12_500, "currency" => "NGN" },
      context: { "country_code" => "NG" }
    )
    second = Oja::Payment::CaptureAllocation.call(
      allocation: @allocation, beneficiary_id: "beneficiary-1", amount_minor: 12_500, currency: "NGN",
      provider: "sandbox", provider_event_id: "evt-capture-replay", payment_reference: "pay-replay-2",
      order_reference: "order-replay-2", correlation_id: "corr-replay-2",
      idempotency_key: "consume:replay-2", payload: { "currency" => "NGN", "amount_minor" => 12_500 },
      context: { "country_code" => "NG" }
    )

    assert first.captured
    assert second.captured
    assert_equal 12_500, @allocation.reload.consumed_minor
    assert_equal 0, Oja::PaymentEvidenceEvent.where(provider: "sandbox", provider_event_id: "evt-capture-replay").count
  end
end
