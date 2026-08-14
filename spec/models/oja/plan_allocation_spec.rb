require "rails_helper"

RSpec.describe Oja::PlanAllocation do
  it "does not double count an active reservation recorded in the ledger" do
    allocation = described_class.allocate
    ledger = instance_double(ActiveRecord::Associations::CollectionProxy)
    reservations = instance_double(ActiveRecord::Associations::CollectionProxy)

    allow(allocation).to receive(:ledger_entries).and_return(ledger)
    allow(allocation).to receive(:reservations).and_return(reservations)

    allow(ledger).to receive(:where).with(entry_type: %w[funding allocation_issued refund reversal adjustment])
      .and_return(instance_double("LedgerCreditScope", sum: 100_000.to_d))
    allow(ledger).to receive(:where).with(entry_type: "consumption")
      .and_return(instance_double("LedgerConsumptionScope", sum: 20_000.to_d))
    allow(reservations).to receive(:active).and_return(
      instance_double("ActiveReservationScope", where: instance_double("ReservationExpiryScope", sum: 30_000.to_d))
    )

    expect(allocation.available_amount).to eq(50_000.to_d)
  end
end
