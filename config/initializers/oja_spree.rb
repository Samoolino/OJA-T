Rails.application.config.to_prepare do
  require_dependency Rails.root.join("app/models/spree/order_decorator").to_s
end
