require_relative "boot"

require "rails/all"
require "spree_core"
require "spree_api"
require "spree_backend"

Bundler.require(*Rails.groups)

module OjaT
  class Application < Rails::Application
    config.load_defaults 7.2
    config.autoload_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/services")
    config.active_record.schema_format = :ruby
  end
end
