# OJA-T's Spree host application configuration.
# Spree 5.6 requires an application-provided user class before its
# user-dependent migrations are executed.
Spree.user_class = "Spree::User"

# This host app currently uses Spree Core/API without the separate Spree Admin
# engine, so admin authentication shares the same persisted user table.
Spree.admin_user_class = "Spree::User"

Rails.application.config.to_prepare do
  require_dependency Rails.root.join("app/models/spree/order_decorator").to_s
end
