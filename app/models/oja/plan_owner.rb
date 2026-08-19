module Oja
  class PlanOwner < ApplicationRecord
    self.table_name = "oja_plan_owners"

    has_many :plans, class_name: "Oja::Plan", dependent: :restrict_with_exception

    enum :status, { active: "active", suspended: "suspended", archived: "archived" }, default: :active

    validates :name, presence: true
  end
end
