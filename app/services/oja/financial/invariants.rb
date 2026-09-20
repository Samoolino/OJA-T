module Oja
  module Financial
    module Invariants
      module_function
      def available(funded_minor:, reserved_minor:, consumed_minor:, released_minor:, reversed_minor:)
        values = [funded_minor, reserved_minor, consumed_minor, released_minor, reversed_minor].map { |v| Integer(v || 0) }
        raise ArgumentError, "financial counters cannot be negative" if values.any?(&:negative?)
        funded, reserved, consumed, released, reversed = values
        available = funded - reserved - consumed + released + reversed
        raise ArgumentError, "available balance cannot be negative" if available.negative?
        available
      end
      def reservation_allowed?(available_minor:, amount_minor:)
        amount = Integer(amount_minor)
        amount.positive? && Integer(available_minor) >= amount
      end
      def consumption_allowed?(reserved_minor:, amount_minor:)
        amount = Integer(amount_minor)
        amount.positive? && Integer(reserved_minor) >= amount
      end
    end
  end
end
