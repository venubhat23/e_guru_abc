# Creates an offered assignment for a set of recipients, reserving capacity under a row lock.
class Assignment
  class Creator
    class Error < StandardError; end

    def self.call(booking:, offer:, recipients:, mode:)
      recipients = Array(recipients)
      raise Error, "No recipients selected" if recipients.empty?
      raise Error, "Some recipients are already assigned" if recipients.any?(&:assignment_id)

      Assignment.transaction do
        offer.lock!
        qty = recipients.size
        raise Error, "#{offer.vendor.name} has no capacity left that week" unless CapacityChecker.available?(offer, booking.requested_delivery_on, qty)

        assignment = booking.assignments.create!(
          vendor: offer.vendor, vendor_offer: offer, quantity: qty, mode:,
          vendor_unit_price_paise: offer.vendor_price_paise, vendor_total_paise: offer.vendor_price_paise * qty,
          advance_pct: offer.advance_pct, balance_terms: offer.balance_terms, credit_days: offer.credit_days,
          expires_at: Setting[:assignment_sla_hours].to_i.hours.from_now
        )
        CapacityReservation.create!(vendor_offer: offer, assignment:, quantity: qty, week_start: CapacityChecker.week_for(booking.requested_delivery_on))
        BookingRecipient.where(id: recipients.map(&:id)).update_all(assignment_id: assignment.id)
        booking.refresh_vendor_subtotal!
        booking.reload.mark_assigned! if booking.assigning? && booking.fully_assigned?
        assignment
      end
    end
  end
end
