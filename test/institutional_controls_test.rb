require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../../app/services", __dir__))
require "oja/financial/invariants"
require "oja/idempotency"
require "oja/geography/policy"
require "oja/settlement/eligibility"

class InstitutionalControlsTest < Minitest::Test
  def test_available_balance_invariant
    assert_equal 700, Oja::Financial::Invariants.available(
      funded_minor: 1_000, reserved_minor: 200, consumed_minor: 100,
      released_minor: 0, reversed_minor: 0
    )
  end

  def test_negative_available_is_rejected
    assert_raises(ArgumentError) do
      Oja::Financial::Invariants.available(
        funded_minor: 100, reserved_minor: 101, consumed_minor: 0,
        released_minor: 0, reversed_minor: 0
      )
    end
  end

  def test_idempotency_is_validated_and_namespaced
    assert_equal "reserve:order-123456", Oja::Idempotency.operation_id(
      prefix: "reserve", idempotency_key: "order-123456"
    )
    assert_raises(ArgumentError) { Oja::Idempotency.validate!("short") }
  end

  def test_geography_policy_matches_normalized_context
    result = Oja::Geography::Policy.evaluate(
      policy: { "country_code" => "NG", "admin_area_1_code" => "LA" },
      context: { "country_code" => "NG", "admin_area_1_code" => "LA" }
    )
    assert result.allowed
    assert_equal "geography_match", result.reason
  end

  def test_settlement_requires_all_execution_gates
    result = Oja::Settlement::Eligibility.call(
      settlement: {
        payment_captured: true,
        vendor_account_ready: true,
        fulfillment_required: true,
        fulfillment_confirmed: true,
        reconciliation_exception: false,
        transfer_idempotency_key: "transfer-123456"
      }
    )
    assert result.eligible
  end
end
