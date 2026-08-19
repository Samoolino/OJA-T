module Oja
  module Settlement
    class Route
      def self.call(settlement:, profile:, scheduler: Oja::Settlement::Scheduler)
        case profile.settlement_strategy
        when "instant"
          scheduler.schedule(settlement.id, profile.settlement_delay_window.to_i)
        when "threshold_batched"
          :awaiting_threshold
        else
          raise ArgumentError, "unsupported settlement strategy"
        end
      end
    end
  end
end
