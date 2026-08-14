source "https://rubygems.org"

gem "rails", "~> 7.2"

# Spree 5.6 is consumed from the upstream monorepo. Pin all Spree
# components to the same release tag for a reproducible application.
spree_source = { github: "spree/spree", tag: "v5.6.0" }

gem "spree", **spree_source
gem "spree_backend", **spree_source
gem "spree_api", **spree_source
gem "spree_core", **spree_source

gem "pg"

group :development, :test do
  gem "rspec-rails"
end
