require "rails_helper"

RSpec.describe Oja::Settlement::Providers::Base do
  subject(:provider) { described_class.new }

  it "requires create_payout to be implemented" do
    expect { provider.create_payout(settlement: instance_double("Settlement")) }
      .to raise_error(NotImplementedError)
  end

  it "requires fetch_payout to be implemented" do
    expect { provider.fetch_payout(reference: "payout_123") }
      .to raise_error(NotImplementedError)
  end

  it "requires cancel_payout to be implemented" do
    expect { provider.cancel_payout(reference: "payout_123") }
      .to raise_error(NotImplementedError)
  end
end
