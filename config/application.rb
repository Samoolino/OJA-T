require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module OjaT
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_paths << Rails.root.join("app/services")
    config.autoload_paths << Rails.root.join("app/models")
    config.eager_load_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/models")
    config.active_record.schema_format = :ruby
    config.generators.system_tests = nil
  end
end
