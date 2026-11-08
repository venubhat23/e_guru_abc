# Marks bookings delivered automatically N days after the last proof of delivery, if no ticket is open.
class AutoConfirmDeliveriesJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = Setting[:auto_confirm_days].to_i.days.ago
    Booking.where(status: "dispatched").find_each do |booking|
      next unless booking.all_delivered? && booking.last_delivered_at && booking.last_delivered_at <= cutoff
      next if booking.open_tickets?
      booking.mark_delivered!
      Bookings::Completer.call(booking)
    end
  end
end
