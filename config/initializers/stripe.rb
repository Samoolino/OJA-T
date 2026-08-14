if defined?(Stripe)
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"] if ENV["STRIPE_SECRET_KEY"].to_s != ""
end
