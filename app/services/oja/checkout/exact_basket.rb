module Oja
  module Checkout
    class ExactBasket
      Result = Struct.new(:valid, :reason, :amount_minor, :currency, :line_items, keyword_init: true)

      def self.call(line_items:, currency:)
        new(line_items:, currency:).call
      end

      def initialize(line_items:, currency:)
        @line_items = Array(line_items)
        @currency = currency.to_s.upcase
      end

      def call
        return Result.new(valid: false, reason: "empty_basket", amount_minor: 0, currency: @currency, line_items: []) if @line_items.empty?
        return Result.new(valid: false, reason: "currency_required", amount_minor: 0, currency: @currency, line_items: []) if @currency.empty?

        normalized = @line_items.map do |item|
          amount = Integer(item[:amount_minor] || item["amount_minor"])
          raise ArgumentError unless amount.positive?
          item_currency = (item[:currency] || item["currency"]).to_s.upcase
          raise ArgumentError if item_currency != @currency
          { "id" => item[:id] || item["id"], "amount_minor" => amount, "currency" => item_currency, "vendor_id" => item[:vendor_id] || item["vendor_id"], "store_id" => item[:store_id] || item["store_id"] }
        end

        Result.new(valid: true, reason: "basket_valid", amount_minor: normalized.sum { |i| i["amount_minor"] }, currency: @currency, line_items: normalized)
      rescue ArgumentError, TypeError
        Result.new(valid: false, reason: "invalid_basket", amount_minor: 0, currency: @currency, line_items: [])
      end
    end
  end
end
