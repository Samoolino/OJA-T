module Oja
  module Settlement
    class ConditionalBatchJob
      def self.perform(vendor_reference:, profile:, transfer_gateway: Oja::Settlement::TransferGateway)
        Oja::Settlement::ConditionalBatch.call(
          vendor_reference: vendor_reference,
          profile: profile,
          transfer_gateway: transfer_gateway
        )
      end
    end
  end
end
