# Evaluates every offer for a booking's bookable against the assignment rules.
class Assignment
  class Eligibility
    Candidate = Struct.new(:offer, :checks, :remaining_capacity, :margin_paise, keyword_init: true) do
      def eligible? = checks.values.all?
      def vendor = offer.vendor
      def failures = checks.reject { |_, ok| ok }.keys
    end

    LABELS = { approved: "Vendor approved", active: "Offer active", regions: "Covers all pincodes", capacity: "Capacity for delivery week",
               lead_time: "Lead time fits date", moq: "Meets MOQ", not_declined: "Hasn't declined this booking" }.freeze

    def initialize(booking, recipients: nil)
      @booking = booking
      @recipients = (recipients || booking.unassigned_recipients).to_a
    end

    def candidates
      offers = @booking.bookable.vendor_offers.includes(vendor: :regions)
      declined = @booking.assignments.where(status: %w[rejected expired]).pluck(:vendor_id)
      qty = @recipients.size
      offers.map do |offer|
        vendor = offer.vendor
        remaining = CapacityChecker.remaining(offer, @booking.requested_delivery_on)
        checks = {
          approved: vendor.approved?,
          active: offer.active?,
          regions: @recipients.all? { |r| vendor.covers_pincode?(pincode: r.pincode, state: r.state, city: r.city) },
          capacity: remaining >= qty,
          lead_time: Date.current + offer.lead_time_days <= @booking.requested_delivery_on,
          moq: qty >= offer.moq,
          not_declined: !declined.include?(vendor.id)
        }
        Candidate.new(offer:, checks:, remaining_capacity: remaining, margin_paise: (@booking.unit_price_paise - offer.vendor_price_paise) * qty)
      end.sort_by { |c| [ c.eligible? ? 0 : 1, c.offer.vendor_price_paise, -c.vendor.rating.to_f ] }
    end

    def eligible = candidates.select(&:eligible?)
  end
end
