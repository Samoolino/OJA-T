module Oja
  class FinancialLedgerEntry
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :id, :integer
    attribute :allocation_id, :integer
    attribute :operation_id, :string
    attribute :idempotency_key, :string
    attribute :entry_type, :string
    attribute :amount_minor, :integer
    attribute :currency, :string
    attribute :correlation_id, :string
    attribute :source_type, :string
    attribute :source_id, :string
    attribute :metadata, :value
  end
end
