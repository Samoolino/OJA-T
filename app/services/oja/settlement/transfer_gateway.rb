module Oja
  module Settlement
    class TransferGateway
      Result = Data.define(:success?, :reference)

      def self.initiate(**_args)
        raise NotImplementedError, "Configure an OJA payment gateway adapter before initiating transfers"
      end
    end
  end
end
