module Oja
  module Settlement
    class Scheduler
      def self.schedule(settlement_id, delay_seconds)
        Rails.logger.info("OJA settlement #{settlement_id} scheduled in #{delay_seconds} seconds")
        :scheduled
      end
    end
  end
end
