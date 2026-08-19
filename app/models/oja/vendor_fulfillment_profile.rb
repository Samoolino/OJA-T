module Oja
  class VendorFulfillmentProfile < ApplicationRecord
    self.table_name = "oja_vendor_fulfillment_profiles"

    FULFILLMENT_MODES = %w[courier pickup digital vendor_delivery].freeze

    enum :fulfillment_mode, {
      courier: "courier",
      pickup: "pickup",
      digital: "digital",
      vendor_delivery: "vendor_delivery"
    }, default: :courier

    validates :vendor_reference, presence: true, uniqueness: true
    validates :processing_time_hours, numericality: { greater_than_or_equal_to: 0 }
    validates :delivery_sla_hours, numericality: { greater_than_or_equal_to: 0 }
  end
end
