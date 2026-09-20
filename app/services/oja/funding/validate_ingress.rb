module Oja
  module Funding
    module ValidateIngress
      module_function
      def call(amount_minor:, currency:, source_type:, source_reference:, provider:, status:)
        amount = Integer(amount_minor)
        raise ArgumentError, "funding amount must be positive" unless amount.positive?
        raise ArgumentError, "currency must be three letters" unless currency.to_s.match?(/\A[A-Z]{3}\z/)
        raise ArgumentError, "funding source is required" if source_type.to_s.empty? || source_reference.to_s.empty?
        raise ArgumentError, "provider is required" if provider.to_s.empty?
        raise ArgumentError, "funding ingress is not verified" unless status.to_s == "verified"
        {"source_type"=>source_type.to_s, "source_reference"=>source_reference.to_s, "provider"=>provider.to_s, "status"=>"verified"}
      end
    end
  end
end
