require "rails_helper"

RSpec.describe Oja::Payment::ProviderRegistry do
  let(:stripe_adapter) { instance_double(Oja::Payment::Providers::StripeAdapter) }
  let(:registry) { described_class.new(providers: { stripe: stripe_adapter }) }

  it "resolves providers by symbolic or string name" do
    expect(registry.fetch(:stripe)).to equal(stripe_adapter)
    expect(registry.fetch("stripe")).to equal(stripe_adapter)
  end

  it "rejects an unregistered provider" do
    expect { registry.fetch(:unknown) }
      .to raise_error(KeyError, /Unknown payment provider/)
  end
end
