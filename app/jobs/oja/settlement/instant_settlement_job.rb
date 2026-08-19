module Oja
  module Settlement
    class InstantSettlementJob
      def self.perform_in(delay_seconds, settlement_id)
        if defined?(Sidekiq)
          perform_in_via_sidekiq(delay_seconds, settlement_id)
        elsif defined?(ActiveJob)
          perform_later(settlement_id, wait: delay_seconds.seconds)
        else
          raise "No background job adapter configured"
        end
      end

      def self.perform(settlement_id, transfer_gateway: Oja::Settlement::TransferGateway)
        settlement = Oja::VendorSettlement.find(settlement_id)
        Oja::Settlement::Execute.call(settlement: settlement, transfer_gateway: transfer_gateway)
      end

      def self.perform_in_via_sidekiq(delay_seconds, settlement_id)
        raise NotImplementedError, "Configure the application's Sidekiq worker adapter"
      end
      private_class_method :perform_in_via_sidekiq
    end
  end
end
