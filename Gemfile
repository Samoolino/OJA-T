source "https://rubygems.org"

gem "rails", "~> 7.2"

gem "stripe"

# Spree 5.6 is consumed from the upstream monorepo. The root `spree`
# gem declares its core/API dependencies; do not declare the monorepo's
# sub-gems as root-level git gems because Bundler resolves a git source
# against its root gemspecs by default.
spree_source = { github: "spree/spree", tag: "v5.6.0" }
gem "spree", **spree_source

gem "pg"

group :development, :test do
  gem "rspec"
  gem "rspec-rails"
end
