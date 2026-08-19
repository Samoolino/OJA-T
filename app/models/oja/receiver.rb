module Oja
  class Receiver < ApplicationRecord
    self.table_name = "oja_receivers"

    has_many :allocations, class_name: "Oja::PlanAllocation", dependent: :restrict_with_exception

    enum :status, { active: "active", suspended: "suspended", archived: "archived" }, default: :active
  end
end
