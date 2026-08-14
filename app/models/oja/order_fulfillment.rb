module Oja
  class OrderFulfillment < ApplicationRecord
    self.table_name = "oja_order_fulfillments"

    MODES = %w[courier pickup digital vendor_delivery].freeze
    STATUSES = %w[pending processing shipped ready_for_pickup delivered failed canceled].freeze

    validates :order_id, presence: true
    validates :vendor_reference, presence: true
    validates :fulfillment_mode, inclusion: { in: MODES }
    validates :status, inclusion: { in: STATUSES }
    validates :idempotency_key, presence: true, uniqueness: true

    def delivered?
      status == "delivered"
    end
  end
end
