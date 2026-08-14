Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "webhooks/payment", to: "webhooks#payment"
      post "webhooks/stripe", to: "webhooks#stripe"
    end
  end
end
