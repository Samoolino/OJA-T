module Oja
  class WebhookEvent < ApplicationRecord
    self.table_name = "oja_webhook_events"

    validates :event_id, :provider, :event_type, :external_reference, presence: true
    validates :event_id, uniqueness: true
  end
end
