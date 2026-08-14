require "spec_helper"

RSpec.describe "vendor-specific OJA settlement routing" do
  describe "strategy contract" do
    it "supports instant and threshold_batched strategies" do
      expect(Oja::VendorSettlementProfile::STRATEGIES).to contain_exactly("instant", "threshold_batched")
    end

    it "calculates the vendor net payout from the configured commission" do
      profile = Oja::VendorSettlementProfile.new(
        vendor_reference: "vendor-1",
        currency: "NGN",
        commission_rate: 5,
        minimum_payout_threshold: 100_000,
        settlement_delay_window: 7200
      )

      expect(profile.payout_amount(100_000)).to eq(BigDecimal("95000"))
    end
  end
end
