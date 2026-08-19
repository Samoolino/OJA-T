module Oja
  class VendorSettlementProfile < ApplicationRecord
    self.table_name = "oja_vendor_settlement_profiles"

    STRATEGIES = %w[instant threshold_batched].freeze

    has_many :order_allocations,
             class_name: "Oja::OrderAllocation",
             foreign_key: :settlement_profile_id,
             dependent: :restrict_with_exception

    enum :settlement_strategy, {
      instant: "instant",
      threshold_batched: "threshold_batched"
    }, default: :instant

    validates :vendor_reference, presence: true, uniqueness: true
    validates :currency, presence: true, length: { is: 3 }
    validates :commission_rate, numericality: { greater_than_or_equal_to: 0, less_than: 100 }
    validates :minimum_payout_threshold, numericality: { greater_than_or_equal_to: 0 }
    validates :settlement_delay_window, numericality: { greater_than_or_equal_to: 0 }

    def payout_amount(gross_amount)
      gross_amount.to_d - (gross_amount.to_d * commission_rate.to_d / 100)
    end
  end
end
