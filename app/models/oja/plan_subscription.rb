module Oja
  class PlanSubscription < ApplicationRecord
    self.table_name = "oja_plan_subscriptions"

    belongs_to :plan, class_name: "Oja::Plan"

    enum :status, { active: "active", paused: "paused", cancelled: "cancelled", past_due: "past_due" }, default: :active

    validates :interval, :currency, presence: true
    validates :amount, numericality: { greater_than: 0 }
  end
end
