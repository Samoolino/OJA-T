module Oja
  class Settlement
    class TransferGateway
      Result = Data.define(:success?, :reference)

      def self.initiate(**_args)
        raise NotImplementedError, "Configure an OJA payment-provider adapter before initiating transfers"
      end
    end
  end
end
