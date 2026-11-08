require "rails_helper"

RSpec.describe Assignment::AutoAssigner do
  let(:company) { create(:company, state: "Karnataka") }
  let(:package) { create(:package) }

  def assigning_booking(**opts)
    draft_booking(company:, package:, **opts).tap { _1.update_column(:status, "assigning") }
  end

  it "picks the cheapest eligible vendor, reserves capacity and marks the booking assigned" do
    expensive = vendor_with_offer(package:, price: 1200_00, rating: 5)
    cheap = vendor_with_offer(package:, price: 900_00, rating: 3)
    booking = assigning_booking(count: 3)
    a = described_class.call(booking)
    expect(a.vendor).to eq(cheap)
    expect(a).to be_offered
    expect(a.vendor_total_paise).to eq(2700_00)
    expect(a.capacity_reservation.quantity).to eq(3)
    expect(booking.reload).to be_assigned
    expect(expensive.assignments).to be_empty
  end

  it "breaks price ties by rating" do
    vendor_with_offer(package:, price: 900_00, rating: 3.5)
    best = vendor_with_offer(package:, price: 900_00, rating: 4.9)
    expect(described_class.call(assigning_booking).vendor).to eq(best)
  end

  it "skips vendors that fail any rule" do
    vendor_with_offer(package:, price: 100_00, states: [ "Kerala" ])                 # region
    vendor_with_offer(package:, price: 200_00, lead_time_days: 30)                 # lead time
    vendor_with_offer(package:, price: 300_00, capacity_per_week: 2)               # capacity
    vendor_with_offer(package:, price: 400_00, moq: 50)                            # MOQ
    vendor_with_offer(package:, price: 500_00).update!(status: "suspended")        # not approved
    ok = vendor_with_offer(package:, price: 950_00)
    expect(described_class.call(assigning_booking(count: 3)).vendor).to eq(ok)
  end

  it "requires regions to cover EVERY recipient pincode" do
    vendor_with_offer(package:, price: 800_00, states: [ "Karnataka" ])
    both = vendor_with_offer(package:, price: 990_00, states: %w[Karnataka Maharashtra])
    emps = [ create(:employee, company:), create(:employee, company:, state: "Maharashtra", city: "Mumbai", pincode: "400001") ]
    booking = draft_booking(company:, package:, employees: emps).tap { _1.update_column(:status, "assigning") }
    expect(described_class.call(booking).vendor).to eq(both)
  end

  it "honours pincode-prefix regions" do
    v = create(:vendor, status: "approved")
    create(:vendor_region, vendor: v, state: "Karnataka", pincode_prefix: "560")
    create(:vendor_offer, vendor: v, offerable: package)
    expect(v.covers_pincode?(pincode: "560034", state: "Karnataka")).to be(true)
    expect(v.covers_pincode?(pincode: "570001", state: "Karnataka")).to be(false)
  end

  it "falls back to manual and alerts ops when nobody is eligible" do
    ops = create(:user, :ops)
    vendor_with_offer(package:, states: [ "Kerala" ])
    booking = assigning_booking
    expect(described_class.call(booking)).to be_nil
    expect(booking.reload.assignment_mode).to eq("manual")
    expect(booking).to be_assigning
    expect(ops.notifications.last.title).to match(/No eligible vendor/)
  end

  it "re-assigns to the next vendor after a rejection" do
    first = vendor_with_offer(package:, price: 800_00)
    second = vendor_with_offer(package:, price: 900_00)
    booking = assigning_booking
    a = described_class.call(booking)
    expect(a.vendor).to eq(first)
    Assignment::Workflow.reject!(a, reason: "Out of stock")
    expect(a.reload).to be_rejected
    expect(a.capacity_reservation).to be_nil
    expect(booking.reload.live_assignments.first.vendor).to eq(second)
    expect(booking).to be_assigned
  end

  describe Assignment::Router do
    it "forces manual above the quantity threshold" do
      Setting[:manual_assignment_qty_threshold] = 2
      vendor_with_offer(package:)
      booking = assigning_booking(count: 3)
      described_class.call(booking)
      expect(booking.reload.assignment_mode).to eq("manual")
      expect(booking.assignments).to be_empty
    end

    it "respects the company assignment-mode override" do
      company.update!(assignment_mode_override: "manual")
      vendor_with_offer(package:)
      booking = assigning_booking
      described_class.call(booking)
      expect(booking.assignments).to be_empty
    end
  end
end
