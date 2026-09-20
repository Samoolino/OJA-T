require_relative "test_helper"

class InstitutionalControlsTest < ActiveSupport::TestCase
  test "financial invariant preserves available balance" do
    assert_equal 850, Oja::Financial::Invariants.available(
      funded_minor: 1_000, reserved_minor: 100, consumed_minor: 100, released_minor: 25, reversed_minor: 25
    )
  end

  test "negative available balance is rejected" do
    assert_raises(ArgumentError) do
      Oja::Financial::Invariants.available(
        funded_minor: 100, reserved_minor: 80, consumed_minor: 30, released_minor: 0, reversed_minor: 0
      )
    end
  end

  test "idempotency key is bounded and operation id is deterministic" do
    key = "checkout:20260920:abc123"
    assert_equal key, Oja::Idempotency.validate!(key)
    assert_equal "reserve:#{key}", Oja::Idempotency.operation_id(prefix: "reserve", idempotency_key: key)
  end

  test "geography policy matches normalized context" do
    policy = { "country_code" => "NG", "admin_area_1_code" => "LA" }
    context = { "country_code" => "NG", "admin_area_1_code" => "LA" }
    result = Oja::Geography::Policy.evaluate(policy:, context:)
    assert result[:allowed]
  end

  test "settlement eligibility blocks reconciliation exceptions" do
    result = Oja::Settlement::Eligibility.call(
      settlement: {
        payment_captured: true,
        vendor_account_ready: true,
        fulfillment_required: false,
        reconciliation_status: "AMOUNT_MISMATCH",
        transfer_idempotency_key: "transfer:20260920:abc123"
      }
    )
    refute result.eligible
    assert_equal "reconciliation_exception", result.reason
  end
end
