module Oja
  module Settlement
    class Reconcile
      SUCCESS_EVENTS = %w[transfer.success settlement.success].freeze
      FAILURE_EVENTS = %w[transfer.failed settlement.failed].freeze

      def self.call(external_reference:, event_type:, settled_at: Time.current, scope: Oja::VendorSettlement)
        settlement = scope.find_by!(external_settlement_reference: external_reference)

        case event_type
        when *SUCCESS_EVENTS
          return settlement if settlement.paid?
          settlement.update!(status: :paid, settled_at: settled_at)
        when *FAILURE_EVENTS
          return settlement if settlement.failed?
          settlement.update!(status: :failed)
        else
          raise ArgumentError, "unsupported settlement event"
        end

        settlement
      end
    end
  end
end
