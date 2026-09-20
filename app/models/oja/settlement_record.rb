module Oja
  class SettlementRecord < ActiveRecord::Base
    self.table_name = "oja_settlement_records"
    STATUSES = %w[created eligible requested confirmed failed blocked].freeze
    validates :order_id, :vendor_reference, :currency, :gross_amount_minor, :net_amount_minor, :status, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :gross_amount_minor, :net_amount_minor, numericality: { greater_than_or_equal_to: 0 }
  end
end
