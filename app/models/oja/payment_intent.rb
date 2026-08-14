module Oja
  class PaymentIntent < ApplicationRecord
    self.table_name = "oja_payment_intents"

    FUNDING_SOURCES = %w[plan_allocation transfer card external_payment].freeze
    AUTHORIZATION_METHODS = %w[biometric_p256 qr_scan device_confirmation coupon payment_link manual].freeze

    enum :status, {
      pending: "pending",
      requires_authorization: "requires_authorization",
      authorized: "authorized",
      funding: "funding",
      order_pending: "order_pending",
      succeeded: "succeeded",
      failed: "failed",
      expired: "expired",
      canceled: "canceled"
    }, default: :pending

    validates :amount, numericality: { greater_than: 0 }
    validates :currency, presence: true, length: { is: 3 }
    validates :funding_source, inclusion: { in: FUNDING_SOURCES }
    validates :authorization_method, inclusion: { in: AUTHORIZATION_METHODS }
    validates :nonce, presence: true, uniqueness: true
    validates :expires_at, presence: true

    def expired_at?(time = Time.current)
      expires_at <= time
    end
  end
end
