module Oja
  class PlanAllocation
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :id, :integer
    attribute :plan_id, :integer
    attribute :beneficiary_id, :string
    attribute :currency, :string
    attribute :funded_minor, :integer, default: 0
    attribute :reserved_minor, :integer, default: 0
    attribute :consumed_minor, :integer, default: 0
    attribute :released_minor, :integer, default: 0
    attribute :reversed_minor, :integer, default: 0
    attribute :active, :boolean, default: true
    attribute :expires_at, :datetime
    attribute :geo_policy, :value

    def available_minor
      Oja::Financial::Invariants.available(
        funded_minor:, reserved_minor:, consumed_minor:, released_minor:, reversed_minor:
      )
    end
  end
end
