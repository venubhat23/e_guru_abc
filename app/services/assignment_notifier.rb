class AssignmentNotifier
  def self.call(assignment)
    booking = assignment.booking
    case assignment.status
    when "offered"
      Notifier.notify(assignment.vendor.users.active, kind: "assignment", title: "New order offer: #{assignment.quantity} kits",
                      body: "Respond within #{Setting[:assignment_sla_hours]}h", url: "/vendor", email: true)
    when "accepted", "rejected", "expired", "dispatched", "delivered"
      Notifier.notify(Notifier.platform_admins, kind: "assignment", title: "#{assignment.vendor.name} #{assignment.status_label.downcase} #{booking.number}",
                      body: assignment.rejection_reason, url: "/admin/bookings/#{booking.to_param}", email: %w[rejected expired].include?(assignment.status))
    end
  end
end
