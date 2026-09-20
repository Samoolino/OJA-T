module Oja
  module Allocation
    class Authorization
      Result = Struct.new(:allowed, :reason, :currency, :evidence, keyword_init: true)

      def self.call(allocation:, amount_minor:, beneficiary_id:, context: {})
        new(allocation:, amount_minor:, beneficiary_id:, context:).call
      end

      def initialize(allocation:, amount_minor:, beneficiary_id:, context:)
        @allocation = allocation
        @amount_minor = Integer(amount_minor)
        @beneficiary_id = beneficiary_id.to_s
        @context = context || {}
      rescue ArgumentError, TypeError
        @allocation = allocation
        @amount_minor = 0
        @beneficiary_id = beneficiary_id.to_s
        @context = context || {}
      end

      def call
        return deny("invalid_amount") unless @amount_minor.positive?
        return deny("allocation_missing") unless @allocation
        return deny("beneficiary_mismatch") unless @allocation.beneficiary_id.to_s == @beneficiary_id
        return deny("allocation_inactive") unless @allocation.active?
        return deny("allocation_expired") if @allocation.expires_at && @allocation.expires_at <= Time.current

        available = @allocation.available_minor
        return deny("insufficient_available_balance", available_minor: available) unless Oja::Financial::Invariants.reservation_allowed?(available_minor: available, amount_minor: @amount_minor)

        geo = Oja::Geography::Policy.evaluate(policy: @allocation.geo_policy, context: @context)
        return deny(geo.reason, geo.evidence) unless geo.allowed

        Result.new(
          allowed: true,
          reason: "allocation_authorized",
          currency: @allocation.currency,
          evidence: {
            "beneficiary_id" => @beneficiary_id,
            "amount_minor" => @amount_minor,
            "available_minor" => available,
            "geography" => geo.evidence
          }
        )
      rescue ArgumentError, TypeError
        deny("invalid_authorization_request")
      end

      private

      def deny(reason, evidence = {})
        Result.new(allowed: false, reason:, currency: @allocation&.currency, evidence:)
      end
    end
  end
end
