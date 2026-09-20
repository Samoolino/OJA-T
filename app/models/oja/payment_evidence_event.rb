module Oja
  class PaymentEvidenceEvent < ActiveRecord::Base
    self.table_name = "oja_payment_evidence_events"

    validates :provider, :provider_event_id, :event_type, presence: true
    validates :amount_minor, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    before_update { raise ActiveRecord::ReadOnlyRecord, "payment evidence is immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "payment evidence is immutable" }
  end
end
