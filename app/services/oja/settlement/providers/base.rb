module Oja
  class Settlement
    module Providers
      class Base
        def create_payout(settlement:, connected_account_id:)
          raise NotImplementedError
        end

        def fetch_payout(reference:)
          raise NotImplementedError
        end

        def cancel_payout(reference:)
          raise NotImplementedError
        end
      end
    end
  end
end
