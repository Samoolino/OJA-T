module Oja
  class VendorSettlement < ApplicationRecord
    self.table_name = "oja_vendor_settlements"

    belongs_to :order_allocation, class_name: "Oja::OrderAllocation"

    enum :status, {
      pending: "pending",
      authorized: "authorized",
      payable: "payable",
      paid: "paid",
      reversed: "reversed",
      failed: "failed"
    }, default: :pending

    validates :vendor_reference, :currency, presence: true
    validates :gross_amount, :platform_fee, :net_amount, numericality: { greater_than_or_equal_to: 0 }
  end
end
