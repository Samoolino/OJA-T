module Oja
  class PaymentEvidenceEvent < ActiveRecord::Base
    self.table_name = "oja_payment_evidence_events"
    before_update { raise ActiveRecord::ReadOnlyRecord, "payment evidence is immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "payment evidence is immutable" }
  end
end
