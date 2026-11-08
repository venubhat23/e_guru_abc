# Who hears about each booking status. HR messages never mention vendors.
class BookingNotifier
  HR_MESSAGES = {
    "pending_approval" => "needs HR admin approval", "awaiting_payment" => "is awaiting payment", "assigning" => "is being matched with our fulfilment partner",
    "confirmed" => "is confirmed — production starts soon", "in_fulfilment" => "is being packed", "partially_dispatched" => "is partly on its way",
    "dispatched" => "has been dispatched", "delivered" => "has been delivered", "completed" => "is complete — your tax invoice is ready",
    "cancelled" => "was cancelled"
  }.freeze
  OPS_STATES = %w[paid assigning assigned confirmed cancelled disputed delivered].freeze

  def self.call(booking)
    status = booking.status
    if (msg = HR_MESSAGES[status])
      hr = status == "pending_approval" ? booking.company.hr_admins : [ booking.created_by, *booking.company.hr_admins ]
      Notifier.notify(hr, kind: "booking", title: "Booking #{booking.number} #{msg}", body: booking.bookable_name, url: "/hr", email: true)
    end
    if OPS_STATES.include?(status)
      users = status == "disputed" ? Notifier.platform_admins(roles: %w[super_admin ops_admin finance_admin]) : Notifier.platform_admins
      Notifier.notify(users, kind: "booking", title: "#{booking.number} → #{booking.status_label}", body: booking.company.name,
                             url: "/admin/bookings/#{booking.to_param}", email: %w[disputed cancelled].include?(status))
    end
  end
end
