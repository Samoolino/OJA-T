require_relative "test_helper"

class InstitutionalControlsTest < ActiveSupport::TestCase
  test "financial invariant preserves available balance" do
    assert_equal 80, Oja::Financial::Invariants.available(funded_minor: 100, reserved_minor: 10, consumed_minor: 20, released_minor: 5, reversed_minor: 5)
  end

  test "financial invariant rejects negative available balance" do
    assert_raises(ArgumentError) { Oja::Financial::Invariants.available(funded_minor: 10, reserved_minor: 9, consumed_minor: 9, released_minor: 0, reversed_minor: 0) }
  end

  test "idempotency keys require safe minimum length" do
    assert_raises(ArgumentError) { Oja::Idempotency.validate!("short") }
    assert Oja::Idempotency.validate!("fund:2026-09-20:abc12345")
  end

  test "geography policy matches normalized context" do
    result = Oja::Geography::Policy.evaluate(
      policy: { "country_code" => "NG", "admin_area_1_code" => "LA" },
      context: { "country_code" => "NG", "admin_area_1_code" => "LA" }
    )
    assert result.allowed
  end

  test "settlement eligibility blocks reconciliation exceptions" do
    result = Oja::Settlement::Eligibility.call(
      settlement_required: true, payment_captured: true, vendor_account_ready: true,
      fulfillment_required: false, fulfillment_confirmed: false,
      reconciliation_status: "AMOUNT_MISMATCH", transfer_idempotency_key: "transfer:2026-09-20:abc12345"
    )
    refute result.allowed
    assert_equal "reconciliation_exception", result.reason
  end
end
