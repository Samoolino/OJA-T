module Oja
  module Funding
    class ValidateIngress
      Result = Struct.new(:valid, :reason, :evidence, keyword_init: true)

      def self.call(amount_minor:, currency:, source_type:, source_reference:, status: "verified")
        new(amount_minor:, currency:, source_type:, source_reference:, status:).call
      end

      def initialize(amount_minor:, currency:, source_type:, source_reference:, status:)
        @amount_minor = Integer(amount_minor)
        @currency = currency.to_s.upcase
        @source_type = source_type.to_s
        @source_reference = source_reference.to_s
        @status = status.to_s
      end

      def call
        return Result.new(valid: false, reason: "amount_must_be_positive", evidence: {}) unless @amount_minor.positive?
        return Result.new(valid: false, reason: "currency_required", evidence: {}) if @currency.empty?
        return Result.new(valid: false, reason: "funding_source_required", evidence: {}) if @source_type.empty? || @source_reference.empty?
        return Result.new(valid: false, reason: "funding_not_verified", evidence: {}) unless @status == "verified"

        Result.new(
          valid: true,
          reason: "funding_ingress_verified",
          evidence: {
            "source_type" => @source_type,
            "source_reference" => @source_reference,
            "amount_minor" => @amount_minor,
            "currency" => @currency
          }
        )
      rescue ArgumentError, TypeError
        Result.new(valid: false, reason: "invalid_funding_input", evidence: {})
      end
    end
  end
end
