module Oja
  module Payment
    class ProviderRegistry
      def initialize(providers: {})
        @providers = providers.transform_keys(&:to_s).freeze
      end

      def fetch(name)
        @providers.fetch(name.to_s) do
          raise KeyError, "Unknown payment provider: #{name}"
        end
      end

      def self.from_environment(env: ENV)
        providers = {}
        providers["stripe"] = Providers::StripeAdapter.new(client: StripeClient.new) if env["STRIPE_SECRET_KEY"].to_s != ""
        new(providers: providers)
      end
    end
  end
end
