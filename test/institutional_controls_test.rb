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
    result = Oja::Geography::Policy.evaluate(policy: {"country_code"=>"NG","admin_area_1_code"=>"LA"}, context: {"country_code"=>"NG","admin_area_1_code"=>"LA"})
    assert result.allowed
  end
  test "settlement eligibility blocks reconciliation exceptions" do
    result = Oja::Settlement::Eligibility.call(settlement_required: true, payment_captured: true, vendor_account_ready: true, fulfillment_required: false, fulfillment_confirmed: false, reconciliation_status: "AMOUNT_MISMATCH", transfer_idempotency_key: "transfer:2026-09-20:abc12345")
    refute result.allowed
    assert_equal "reconciliation_exception", result.reason
  end
  test "funding requires verified ingress and is persisted atomically" do
    plan = Oja::Plan.create!(plan_owner_id: 1, name: "Test", currency: "NGN", funding_target_minor: 100_000)
    allocation = Oja::PlanAllocation.create!(plan:, beneficiary_id: "beneficiary-1", currency: "NGN")
    result = Oja::Funding::Issue.call(allocation:, amount_minor: 10_000, currency: "NGN", source_type: "stripe_payment", source_reference: "pi_test_1", provider: "stripe", status: "verified", idempotency_key: "fund:test:abc12345", correlation_id: "corr-1")
    assert result.funded
    assert_equal 10_000, allocation.reload.funded_minor
    assert_equal 1, Oja::FundingIngress.count
    assert_equal "fund", Oja::FinancialLedgerEntry.first.entry_type
  end
  test "reservation is atomic and idempotent" do
    plan = Oja::Plan.create!(plan_owner_id: 2, name: "Test", currency: "NGN", funding_target_minor: 100_000)
    allocation = Oja::PlanAllocation.create!(plan:, beneficiary_id: "beneficiary-2", currency: "NGN", funded_minor: 20_000)
    result = Oja::Allocation::Reservation.call(allocation:, amount_minor: 5_000, beneficiary_id: "beneficiary-2", idempotency_key: "reserve:test:abc12345", correlation_id: "corr-2")
    assert result.reserved
    assert_equal 5_000, allocation.reload.reserved_minor
    replay = Oja::Allocation::Reservation.call(allocation:, amount_minor: 5_000, beneficiary_id: "beneficiary-2", idempotency_key: "reserve:test:abc12345", correlation_id: "corr-2")
    assert_equal "reservation_replayed", replay.reason
    assert_equal 1, Oja::FinancialLedgerEntry.where(entry_type: "reserve").count
  end
  test "consume release and reverse are bounded" do
    plan = Oja::Plan.create!(plan_owner_id: 3, name: "Test", currency: "NGN", funding_target_minor: 100_000)
    allocation = Oja::PlanAllocation.create!(plan:, beneficiary_id: "beneficiary-3", currency: "NGN", funded_minor: 20_000, reserved_minor: 8_000)
    assert Oja::Financial::LedgerOperation.call(allocation:, entry_type: "consume", amount_minor: 3_000, idempotency_key: "consume:test:abc12345", correlation_id: "corr-3").applied
    assert Oja::Financial::LedgerOperation.call(allocation:, entry_type: "release", amount_minor: 2_000, idempotency_key: "release:test:abc12345", correlation_id: "corr-4").applied
    assert Oja::Financial::LedgerOperation.call(allocation:, entry_type: "reverse", amount_minor: 1_000, idempotency_key: "reverse:test:abc12345", correlation_id: "corr-5").applied
    allocation.reload
    assert_equal 5_000, allocation.reserved_minor
    assert_equal 2_000, allocation.consumed_minor
    assert_equal 1_000, allocation.reversed_minor
  end
end
