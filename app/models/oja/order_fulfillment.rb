module Oja
  class OrderFulfillment < ActiveRecord::Base
    self.table_name = "oja_order_fulfillments"
    MODES = %w[delivery pickup digital].freeze
    STATUSES = %w[pending confirmed failed cancelled].freeze
    validates :order_id, :vendor_reference, :fulfillment_mode, :status, :idempotency_key, presence: true
    validates :fulfillment_mode, inclusion: { in: MODES }
    validates :status, inclusion: { in: STATUSES }
  end
end
