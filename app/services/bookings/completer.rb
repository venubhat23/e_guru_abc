# Completes a delivered booking once every vendor payout is received.
# Status change, ledger postings and tax invoice happen in ONE transaction.
module Bookings
  class Completer
    def self.call(booking)
      booking.reload
      return false unless booking.delivered? && booking.all_payouts_received?
      Booking.transaction do
        booking.lock!
        booking.complete!
        Ledger::Poster.post!(booking)
        Invoices::Issuer.tax_invoice!(booking)
      end
      BookingMailer.completed(booking).deliver_later
      true
    end
  end
end
