# Vendor-side assignment lifecycle with booking roll-ups and payout scheduling.
class Assignment
  class Workflow
    class << self
      def accept!(assignment)
        Assignment.transaction do
          assignment.accept!
          Payouts::Scheduler.on_accept(assignment)
          booking = assignment.booking.reload
          booking.confirm! if booking.assigned? && booking.all_assignments_accepted?
        end
      end

      def reject!(assignment, reason:)
        assignment.rejection_reason = reason
        release!(assignment, status: "rejected", reason:)
      end

      def expire!(assignment) = release!(assignment, status: "expired", reason: "SLA expired")

      # Rejected/expired: release capacity, unassign recipients, return booking to assigning and retry.
      def release!(assignment, status:, reason:, reassign: true)
        booking = assignment.booking
        Assignment.transaction do
          if assignment.offered?
            status == "rejected" ? assignment.reject! : assignment.expire!
          else
            assignment.update!(status: "expired", rejection_reason: reason)
          end
          assignment.capacity_reservation&.destroy!
          assignment.recipients.update_all(assignment_id: nil, status: "pending")
          booking.refresh_vendor_subtotal!
          booking.reload.return_to_assigning! if booking.assigned?
        end
        Assignment::AutoAssigner.call(booking.reload) if reassign && booking.assigning? && booking.assignment_mode == "auto"
      end

      def start_production!(assignment)
        Assignment.transaction do
          assignment.start_production!
          assignment.recipients.update_all(status: "in_production")
          booking = assignment.booking.reload
          booking.start_fulfilment! if booking.confirmed?
        end
      end

      def mark_ready!(assignment, photos: [])
        assignment.qc_photos.attach(photos) if photos.present?
        assignment.mark_ready!
      end

      # tracking: { recipient_id => { courier:, awb: } }
      def dispatch!(assignment, tracking:)
        Assignment.transaction do
          assignment.recipients.each do |r|
            t = tracking[r.id] || tracking[r.id.to_s]
            next unless t && t[:awb].present?
            r.update!(courier: t[:courier], awb: t[:awb], status: "dispatched", dispatched_at: Time.current)
          end
          assignment.mark_dispatched!
          booking = assignment.booking.reload
          if booking.all_dispatched?
            booking.mark_dispatched!
          elsif booking.in_fulfilment?
            booking.partially_dispatch!
          end
        end
      end

      def deliver!(assignment, recipient_ids: nil, proofs: [])
        Assignment.transaction do
          scope = assignment.recipients.where(status: "dispatched")
          scope = scope.where(id: recipient_ids) if recipient_ids
          scope.update_all(status: "delivered", delivered_at: Time.current)
          assignment.delivery_proofs.attach(proofs) if proofs.present?
          if assignment.recipients.where.not(status: "delivered").none? && assignment.dispatched?
            assignment.mark_delivered!
            Payouts::Scheduler.on_delivered(assignment)
          end
        end
      end
    end
  end
end
