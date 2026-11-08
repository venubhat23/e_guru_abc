# Decides auto vs manual assignment. Manual when: global/company mode is manual,
# quantity exceeds the threshold, or the bookable is a custom box.
class Assignment
  class Router
    def self.call(booking)
      manual = booking.company.assignment_mode == "manual" ||
               booking.quantity > Setting[:manual_assignment_qty_threshold].to_i ||
               booking.bookable_type == "CustomBox"
      if manual
        booking.update_column(:assignment_mode, "manual")
        Notifier.notify(Notifier.platform_admins, kind: "assignment", title: "Manual assignment needed: #{booking.number}",
                        body: "#{booking.company.name} · #{booking.quantity} kits", url: "/admin/bookings/#{booking.to_param}", email: true)
        nil
      else
        booking.update_column(:assignment_mode, "auto")
        AutoAssigner.call(booking)
      end
    end
  end
end
