# HR submits (or an HR admin approves) a booking. Credit-terms companies skip payment, so the
# booking lands straight in `assigning` and must be routed to vendor assignment right away.
module Bookings
  class Submitter
    def self.submit!(booking) = transition!(booking, :submit!)
    def self.approve!(booking) = transition!(booking, :approve!)

    def self.transition!(booking, event)
      booking.public_send(event)
      Assignment::Router.call(booking) if booking.assigning?
      booking
    end
  end
end
