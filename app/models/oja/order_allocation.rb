module Oja
  class OrderAllocation < ApplicationRecord
    self.table_name = "oja_order_allocations"

    belongs_to :allocation, class_name: "Oja::PlanAllocation"
    belongs_to :reservation, class_name: "Oja::AllocationReservation"

    validates :amount, :currency, presence: true
    validates :amount, numericality: { greater_than: 0 }
  end
end
