# Picks the cheapest eligible vendor (then highest rating), reserves capacity and offers the job.
# Falls back to manual + ops alert when nobody is eligible.
class Assignment
  class AutoAssigner
    def self.call(booking)
      recipients = booking.unassigned_recipients.to_a
      return if recipients.empty?

      candidate = Eligibility.new(booking, recipients:).eligible.first
      if candidate
        Creator.call(booking:, offer: candidate.offer, recipients:, mode: "auto")
      else
        booking.update_column(:assignment_mode, "manual")
        Notifier.notify(Notifier.platform_admins, kind: "assignment", title: "No eligible vendor for #{booking.number}",
                        body: "Switched to manual assignment", url: "/admin/bookings/#{booking.to_param}", email: true)
        nil
      end
    end
  end
end
