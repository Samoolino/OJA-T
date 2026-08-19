module Oja
  class Plan < ApplicationRecord
    self.table_name = "oja_plans"

    belongs_to :plan_owner, class_name: "Oja::PlanOwner"
    has_many :subscriptions, class_name: "Oja::PlanSubscription", dependent: :restrict_with_exception
    has_many :fundings, class_name: "Oja::PlanFunding", dependent: :restrict_with_exception
    has_many :allocations, class_name: "Oja::PlanAllocation", dependent: :restrict_with_exception

    enum :status, { draft: "draft", active: "active", suspended: "suspended", expired: "expired", archived: "archived" }, default: :draft
    enum :allocation_mode, { manual: "manual", scheduled: "scheduled", rules_based: "rules_based" }, default: :manual
    enum :spending_mode, { single_allocation: "single_allocation", multi_allocation: "multi_allocation" }, default: :multi_allocation

    validates :name, :currency, presence: true
    validates :funding_target, numericality: { greater_than_or_equal_to: 0 }
  end
end
