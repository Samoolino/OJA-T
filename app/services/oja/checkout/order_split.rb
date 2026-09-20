module Oja
  module Checkout
    class OrderSplit
      def self.call(order_reference:, cart_reference:, line_items:, correlation_id:)
        items = Array(line_items)
        raise ArgumentError, "order_reference is required" if order_reference.to_s.empty?
        raise ArgumentError, "cart_reference is required" if cart_reference.to_s.empty?
        raise ArgumentError, "correlation_id is required" if correlation_id.to_s.empty?
        raise ArgumentError, "line_items are required" if items.empty?
        grouped = items.group_by { |i| [(i[:vendor_id] || i["vendor_id"]).to_s, (i[:store_id] || i["store_id"]).to_s] }
        raise ArgumentError, "vendor/store is required" if grouped.keys.any? { |vendor, store| vendor.empty? || store.empty? }
        grouped.map do |(vendor_id, store_id), group|
          currencies = group.map { |i| (i[:currency] || i["currency"]).to_s.upcase }.uniq
          raise ArgumentError, "mixed currency in split" unless currencies.one?
          amount = group.sum { |i| Integer(i[:amount_minor] || i["amount_minor"]) }
          raise ArgumentError, "split amount must be positive" unless amount.positive?
          Oja::OrderSplit.find_or_create_by!(order_reference:, vendor_id: vendor_id.to_i, vendor_store_id: store_id.to_i) do |split|
            split.cart_reference = cart_reference
            split.currency = currencies.first
            split.amount_minor = amount
            split.correlation_id = correlation_id
            split.line_items = group
          end
        end
      end
    end
  end
end
