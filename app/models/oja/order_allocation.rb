module Oja
  class OrderAllocation < ApplicationRecord
    self.table_name = "oja_order_allocations"

    belongs_to :allocation, class_name: "Oja::PlanAllocation"
    belongs_to :reservation, class_name: "Oja::AllocationReservation"
    belongs_to :settlement_profile, class_name: "Oja::VendorSettlementProfile"
    has_many :vendor_settlements, class_name: "Oja::VendorSettlement", dependent: :restrict_with_exception

    validates :amount, :currency, :vendor_reference, presence: true
    validates :amount, numericality: { greater_than: 0 }
  end
end
