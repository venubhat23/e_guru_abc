module SupplyHelpers
  # An approved vendor covering `states`, offering `package`.
  def vendor_with_offer(package:, states: [ "Karnataka" ], price: 1000_00, rating: 4.0, **offer_attrs)
    vendor = create(:vendor, status: "approved", rating:)
    states.each { |s| create(:vendor_region, vendor:, state: s) }
    create(:vendor_offer, vendor:, offerable: package, vendor_price_paise: price, **offer_attrs)
    vendor
  end

  def draft_booking(company:, package:, count: 5, days: 14, employees: nil)
    employees ||= create_list(:employee, count, company:, state: company.state)
    Bookings::Creator.call(company:, user: nil, bookable: package, employees:, requested_delivery_on: Date.current + days)
  end
end

RSpec.configure { |c| c.include SupplyHelpers }
