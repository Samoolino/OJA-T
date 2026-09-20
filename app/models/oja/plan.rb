module Oja
  class Plan
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :id, :integer
    attribute :plan_owner_id, :integer
    attribute :name, :string
    attribute :currency, :string
    attribute :funding_target_minor, :integer
    attribute :status, :string, default: "draft"
    attribute :starts_at, :datetime
    attribute :ends_at, :datetime

    STATUSES = %w[draft active archived].freeze
  end
end
