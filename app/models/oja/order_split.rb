module Oja
  class OrderSplit < ActiveRecord::Base
    self.table_name = "oja_order_splits"
    STATUSES = %w[CREATED REQUIRES_METHOD REQUIRES_AUTH PROCESSING AUTHORIZED CAPTURED FAILED CANCELLED REFUNDED DISPUTED SETTLED].freeze
    FULFILLMENT_STATUSES = %w[PENDING CONFIRMED FAILED].freeze
    validates :order_reference, :cart_reference, :vendor_id, :vendor_store_id, :currency, :status, :fulfillment_status, :correlation_id, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :fulfillment_status, inclusion: { in: FULFILLMENT_STATUSES }
    validates :amount_minor, numericality: { greater_than_or_equal_to: 0 }
  end
end
