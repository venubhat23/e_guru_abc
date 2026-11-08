# Moves a booking forward once it is fully paid, then routes it to assignment.
module Bookings
  class PaymentApplier
    def self.call(booking)
      booking.reload
      return unless booking.awaiting_payment? && booking.balance_due_paise.zero?
      booking.mark_paid!
      booking.start_assigning!
      Assignment::Router.call(booking)
    end
  end
end
