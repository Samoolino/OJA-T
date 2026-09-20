module Oja
  module Payment
    class CaptureOrderSplit
      Result = Struct.new(:captured, :reason, :split, :fulfillment, :settlement, :evidence, keyword_init: true)

      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(order_id:, split:, allocation:, beneficiary_id:, amount_minor:, currency:, provider:, provider_event_id:,
                     payment_reference:, correlation_id:, idempotency_key:, payload:, fulfillment_mode:, fulfillment_idempotency_key:,
                     settlement_idempotency_key:, platform_fee_minor: 0, context: {})
        @order_id = order_id
        @split = split
        @allocation = allocation
        @beneficiary_id = beneficiary_id
        @amount_minor = Integer(amount_minor)
        @currency = currency.to_s.upcase
        @provider = provider
        @provider_event_id = provider_event_id
        @payment_reference = payment_reference
        @correlation_id = correlation_id
        @idempotency_key = idempotency_key
        @payload = payload
        @fulfillment_mode = fulfillment_mode
        @fulfillment_idempotency_key = fulfillment_idempotency_key
        @settlement_idempotency_key = settlement_idempotency_key
        @platform_fee_minor = Integer(platform_fee_minor)
        @context = context
      end

      def call
        Oja::Idempotency.validate!(@idempotency_key)
        Oja::Idempotency.validate!(@fulfillment_idempotency_key)
        Oja::Idempotency.validate!(@settlement_idempotency_key)
        raise ArgumentError, "correlation_id is required" if @correlation_id.to_s.empty?

        ActiveRecord::Base.transaction do
          split = Oja::OrderSplit.lock.find(@split.id)
          capture = Oja::Payment::CaptureAllocation.call(
            allocation: @allocation,
            beneficiary_id: @beneficiary_id,
            amount_minor: @amount_minor,
            currency: @currency,
            provider: @provider,
            provider_event_id: @provider_event_id,
            payment_reference: @payment_reference,
            order_reference: split.order_reference,
            correlation_id: @correlation_id,
            idempotency_key: @idempotency_key,
            payload: @payload,
            context: @context
          )
          unless capture.captured
            return Result.new(captured: false, reason: capture.reason, split: split, evidence: capture.evidence)
          end

          split.status = "CAPTURED"
          split.payment_reference = @payment_reference.to_s
          split.fulfillment_status = "PENDING"
          split.correlation_id = @correlation_id.to_s
          split.save!

          fulfillment = Oja::Fulfillment::Create.call(
            order: Struct.new(:id).new(@order_id),
            vendor_reference: split.vendor_id.to_s,
            mode: @fulfillment_mode,
            idempotency_key: @fulfillment_idempotency_key,
            correlation_id: @correlation_id
          )

          settlement = Oja::Settlement::Build.call(
            order_id: @order_id,
            vendor_reference: split.vendor_id.to_s,
            currency: split.currency,
            gross_amount_minor: split.amount_minor,
            platform_fee_minor: @platform_fee_minor,
            allocation_id: @allocation.id,
            correlation_id: @correlation_id,
            idempotency_key: @settlement_idempotency_key
          )

          Result.new(captured: true, reason: "capture_order_split_accepted", split: split,
                     fulfillment: fulfillment, settlement: settlement, evidence: capture.evidence)
        end
      rescue ArgumentError, TypeError
        Result.new(captured: false, reason: "invalid_capture_order_split_request", evidence: {})
      end
    end
  end
end
