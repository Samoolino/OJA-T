module Oja
  module Settlement
    class ScheduleThresholdBatch
      def self.call(vendor_reference:, profile:, job: Oja::Settlement::ConditionalBatchJob)
        return :unsupported unless profile.settlement_strategy == "threshold_batched"
        return :invalid_threshold if profile.minimum_payout_threshold.to_d <= 0

        if job.respond_to?(:perform_later)
          job.perform_later(vendor_reference: vendor_reference, profile: profile)
        elsif job.respond_to?(:perform)
          job.perform(vendor_reference: vendor_reference, profile: profile)
        else
          raise ArgumentError, "threshold settlement job must support perform_later or perform"
        end
      end
    end
  end
end
