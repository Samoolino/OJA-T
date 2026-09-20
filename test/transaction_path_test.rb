require_relative "test_helper"

class TransactionPathTest < ActiveSupport::TestCase
  setup do
    @plan = Oja::Plan.create!(
      plan_owner_id: 1,
      name: "Sandbox Plan",
      currency: "NGN",
      funding_target_minor: 100_000,
      status: "active"
    )
    @allocation = Oja::PlanAllocation.create!(
      plan: @plan,
      beneficiary_id: "beneficiary-1",
      currency: "NGN",
      geo_policy: { "country_code" => "NG" }
    )
  end

  test "verified funding is persisted and increases funded balance exactly once" do
    result = Oja::Funding::Issue.call(
      allocation: @allocation,
      amount_minor: 50_000,
      currency: "NGN",
      source_type: "test_funding",
      source_reference: "sandbox-1",
      provider: "sandbox",
      status: "verified",
      idempotency_key: "fund:sandbox-1",
      correlation_id: "corr:sandbox-1"
    )

    assert result.funded
    assert_equal 50_000, @allocation.reload.funded_minor
    assert_equal 1, Oja::FundingIngress.where(source_reference: "sandbox-1").count
    assert_equal 1, @allocation.ledger_entries.where(entry_type: "fund").count
  end

  test "checkout authorization and reservation is atomic and idempotent" do
    Oja::Funding::Issue.call(
      allocation: @allocation,
      amount_minor: 50_000,
      currency: "NGN",
      source_type: "test_funding",
      source_reference: "sandbox-2",
      provider: "sandbox",
      status: "verified",
      idempotency_key: "fund:sandbox-2",
      correlation_id: "corr:sandbox-2"
    )

    items = [{ id: "sku-1", amount_minor: 12_500, currency: "NGN", vendor_id: 10, store_id: 20 }]
    first = Oja::Checkout::AuthorizeAndReserve.call(
      allocation: @allocation,
      beneficiary_id: "beneficiary-1",
      line_items: items,
      currency: "NGN",
      idempotency_key: "reserve:sandbox-1",
      correlation_id: "corr:sandbox-1",
      context: { "country_code" => "NG" }
    )
    second = Oja::Checkout::AuthorizeAndReserve.call(
      allocation: @allocation,
      beneficiary_id: "beneficiary-1",
      line_items: items,
      currency: "NGN",
      idempotency_key: "reserve:sandbox-1",
      correlation_id: "corr:sandbox-1",
      context: { "country_code" => "NG" }
    )

    assert first.reserved
    assert second.reserved
    assert_equal 12_500, @allocation.reload.reserved_minor
    assert_equal 1, @allocation.ledger_entries.where(entry_type: "reserve").count
  end
end
