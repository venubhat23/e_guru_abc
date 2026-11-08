require "rails_helper"

RSpec.describe Assignment::CapacityChecker do
  let(:company) { create(:company) }
  let(:package) { create(:package) }
  let!(:vendor) { vendor_with_offer(package:, capacity_per_week: 10) }
  let(:offer) { vendor.offers.first }

  it "reports remaining capacity per delivery week" do
    booking = draft_booking(company:, package:, count: 4)
    Assignment::Creator.call(booking:, offer:, recipients: booking.recipients.to_a, mode: "manual")
    week = booking.requested_delivery_on
    expect(described_class.remaining(offer, week)).to eq(6)
    expect(described_class.remaining(offer, week + 7)).to eq(10)
    expect(described_class.available?(offer, week, 7)).to be(false)
  end

  it "refuses to over-reserve" do
    b1 = draft_booking(company:, package:, count: 8)
    b2 = draft_booking(company:, package:, count: 5)
    Assignment::Creator.call(booking: b1, offer:, recipients: b1.recipients.to_a, mode: "manual")
    expect { Assignment::Creator.call(booking: b2, offer:, recipients: b2.recipients.to_a, mode: "manual") }.to raise_error(Assignment::Creator::Error, /capacity/)
  end
end
