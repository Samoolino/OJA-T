module Oja
  class AllocationReservation < ApplicationRecord
    self.table_name = "oja_allocation_reservations"

    belongs_to :allocation, class_name: "Oja::PlanAllocation"

    enum :status, { active: "active", released: "released", consumed: "consumed", expired: "expired" }, default: :active

    validates :amount, :currency, :idempotency_key, :expires_at, presence: true
    validates :amount, numericality: { greater_than: 0 }
    validates :idempotency_key, uniqueness: true
  end
end
