require "rails_helper"

RSpec.describe Ledger::Poster do
  let(:company) { create(:company) }
  let(:booking) do
    create(:package).then do |pkg|
      vendor_with_offer(package: pkg)
      draft_booking(company:, package: pkg).tap do |b|
        b.update_columns(status: "completed", hr_subtotal_paise: 10_000_00, vendor_subtotal_paise: 7000_00)
        b.payments.create!(method: "razorpay", amount_paise: 11_800_00, gateway_fee_paise: 236_00, status: "verified")
      end
    end
  end

  it "posts revenue, marketing reserve and gateway fees" do
    described_class.post!(booking)
    entries = booking.ledger_entries.to_h { [ _1.account, _1.amount_paise ] }
    expect(entries).to eq("revenue" => 3000_00, "marketing_reserve" => 1400_00, "gateway_fees" => 236_00)
    expect(described_class.totals[:net_contribution]).to eq(3000_00 - 1400_00 - 236_00)
  end

  it "uses the marketing % setting" do
    Setting[:marketing_reserve_pct] = 10
    described_class.post!(booking)
    expect(booking.ledger_entries.find_by(account: "marketing_reserve").amount_paise).to eq(700_00)
  end

  it "is idempotent and refuses incomplete bookings" do
    2.times { described_class.post!(booking) }
    expect(booking.ledger_entries.count).to eq(3)
    booking.update_column(:status, "delivered")
    expect { described_class.post!(booking.reload) }.to raise_error(ArgumentError)
  end
end
