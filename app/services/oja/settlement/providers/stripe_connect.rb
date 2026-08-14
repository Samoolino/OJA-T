module Oja
  class Settlement
    module Providers
      class StripeConnect < Base
        class Error < StandardError; end
        class NotEligible < Error; end
        class TransfersDisabled < Error; end
        class ProviderFailure < Error; end

        def initialize(secret_key: ENV["STRIPE_SECRET_KEY"], account_client: ::Stripe::Account, transfer_client: ::Stripe::Transfer)
          @secret_key = secret_key
          @account_client = account_client
          @transfer_client = transfer_client
        end

        def create_payout(settlement:, connected_account_id:)
          raise NotEligible, "settlement must be eligible" unless %w[eligible processing].include?(settlement.status)
          raise ArgumentError, "connected_account_id is required" if connected_account_id.to_s.empty?

          if settlement.provider_reference.to_s != ""
            return { id: settlement.provider_reference, status: "processing", reused: true }
          end

          configure_stripe!
          account = @account_client.retrieve(connected_account_id)
          transfers_status = account.capabilities && account.capabilities["transfers"]
          raise TransfersDisabled, "connected account cannot receive transfers" unless transfers_status == "active"

          transfer = @transfer_client.create(
            {
              amount: settlement.net_amount,
              currency: settlement.currency.downcase,
              destination: connected_account_id,
              metadata: {
                oja_settlement_reference: settlement.settlement_reference
              }
            },
            { idempotency_key: settlement.settlement_reference }
          )

          settlement.update!(
            status: "processing",
            provider_reference: transfer.id
          )

          { id: transfer.id, status: "processing", reused: false }
        rescue NotEligible, TransfersDisabled, ArgumentError
          raise
        rescue ::Stripe::StripeError => e
          raise ProviderFailure, e.message
        end

        def fetch_payout(reference:)
          configure_stripe!
          transfer = @transfer_client.retrieve(reference)
          { id: transfer.id, status: transfer.status }
        rescue ::Stripe::StripeError => e
          raise ProviderFailure, e.message
        end

        def cancel_payout(reference:)
          configure_stripe!
          transfer = @transfer_client.retrieve(reference)
          { id: transfer.id, status: transfer.status }
        rescue ::Stripe::StripeError => e
          raise ProviderFailure, e.message
        end

        private

        def configure_stripe!
          ::Stripe.api_key = @secret_key if @secret_key && !@secret_key.empty?
        end
      end
    end
  end
end
