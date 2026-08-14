module Oja
  class Settlement
    class Scheduler
      def self.schedule(settlement_id, delay_seconds, job: Oja::Settlement::InstantSettlementJob)
        if job.respond_to?(:perform_in)
          job.perform_in(delay_seconds, settlement_id)
        else
          raise ArgumentError, "settlement job must support perform_in"
        end
      end
    end
  end
end
