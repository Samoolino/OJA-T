module Oja
  class FundingIngress < ActiveRecord::Base
    self.table_name = "oja_funding_ingresses"
    validates :amount_minor, numericality: { greater_than: 0 }
    before_update { raise ActiveRecord::ReadOnlyRecord, "funding ingress is immutable" }
    before_destroy { raise ActiveRecord::ReadOnlyRecord, "funding ingress is immutable" }
  end
end
