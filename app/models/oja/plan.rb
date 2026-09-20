module Oja
  class Plan < ActiveRecord::Base
    self.table_name = "oja_plans"

    has_many :allocations, class_name: "Oja::PlanAllocation", foreign_key: :plan_id, inverse_of: :plan

    STATUSES = %w[draft active archived].freeze

    validates :name, :currency, presence: true
    validates :funding_target_minor, numericality: { greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: STATUSES }
  end
end
