module Oja
  class PlanFunding < ApplicationRecord
    self.table_name = "oja_plan_fundings"

    belongs_to :plan, class_name: "Oja::Plan"

    enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed", reversed: "reversed" }, default: :pending

    validates :amount, :currency, presence: true
    validates :amount, numericality: { greater_than: 0 }
  end
end
