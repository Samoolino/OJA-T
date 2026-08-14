module Oja
  class Settlement < ApplicationRecord
    self.table_name = "settlements"

    STATUSES = %w[pending eligible processing settled failed].freeze
    STRATEGIES = %w[instant delayed threshold_batch].freeze

    validates :vendor_reference, :currency, :settlement_reference, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :settlement_strategy, inclusion: { in: STRATEGIES }
    validates :gross_amount, :platform_fee, :net_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    validate :net_amount_does_not_exceed_gross_amount

    private

    def net_amount_does_not_exceed_gross_amount
      return if gross_amount.blank? || platform_fee.blank? || net_amount.blank?
      return if net_amount == gross_amount - platform_fee

      errors.add(:net_amount, "must equal gross amount less platform fee")
    end
  end
end
