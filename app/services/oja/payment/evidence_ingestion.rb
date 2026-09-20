require "digest"
require "json"

module Oja
  module Payment
    class EvidenceIngestion
      Result = Struct.new(:event, :replayed, keyword_init: true)

      def self.call(provider:, provider_event_id:, event_type:, payment_reference:, order_reference:, currency:, amount_minor:, correlation_id:, payload:, occurred_at: nil)
        new(provider:, provider_event_id:, event_type:, payment_reference:, order_reference:, currency:, amount_minor:, correlation_id:, payload:, occurred_at:).call
      end

      def initialize(**attrs)
        @attrs = attrs
      end

      def call
        provider = @attrs[:provider].to_s
        event_id = @attrs[:provider_event_id].to_s
        raise ArgumentError, "provider is required" if provider.empty?
        raise ArgumentError, "provider_event_id is required" if event_id.empty?

        fingerprint = Digest::SHA256.hexdigest(JSON.generate(canonical(@attrs[:payload] || {})))
        existing = Oja::PaymentEvidenceEvent.find_by(provider:, provider_event_id: event_id)
        if existing
          raise ArgumentError, "provider event payload mismatch" unless existing.payload_fingerprint == fingerprint
          return Result.new(event: existing, replayed: true)
        end

        event = Oja::PaymentEvidenceEvent.create!(
          provider:,
          provider_event_id: event_id,
          event_type: @attrs[:event_type].to_s,
          payment_reference: @attrs[:payment_reference],
          order_reference: @attrs[:order_reference],
          currency: @attrs[:currency].to_s.upcase.presence,
          amount_minor: @attrs[:amount_minor],
          correlation_id: @attrs[:correlation_id],
          payload_fingerprint: fingerprint,
          payload: @attrs[:payload] || {},
          occurred_at: @attrs[:occurred_at]
        )
        Result.new(event:, replayed: false)
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      private

      def canonical(value)
        case value
        when Hash
          value.keys.map(&:to_s).sort.each_with_object({}) { |key, h| h[key] = canonical(value[key] || value[key.to_sym]) }
        when Array
          value.map { |item| canonical(item) }
        else
          value
        end
      end
    end
  end
end
