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
    end
  end
end
