module Oja
  module Fulfillment
    class Transition
      ALLOWED = {
        "pending" => %w[confirmed failed cancelled],
        "failed" => %w[pending],
        "cancelled" => [],
        "confirmed" => []
      }.freeze
      def self.call(fulfillment:, status:, correlation_id:, tracking_reference: nil)
        raise ArgumentError, "fulfillment is required" unless fulfillment
        target = status.to_s
        raise ArgumentError, "invalid fulfillment status" unless Oja::OrderFulfillment::STATUSES.include?(target)
        raise ArgumentError, "correlation_id is required" if correlation_id.to_s.empty?
        ActiveRecord::Base.transaction do
          row = Oja::OrderFulfillment.lock.find(fulfillment.id)
          return row if row.status == target
          raise ArgumentError, "invalid fulfillment transition" unless ALLOWED.fetch(row.status).include?(target)
          row.status = target
          row.correlation_id = correlation_id
          row.tracking_reference = tracking_reference if tracking_reference
          row.confirmed_at = Time.current if target == "confirmed"
          row.save!
          row
        end
      end
    end
  end
end
