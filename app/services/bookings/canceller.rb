# Cancels before vendor confirmation: releases vendors, refunds in full and issues a credit note.
module Bookings
  class Canceller
    class Error < StandardError; end

    def self.call(booking:, reason:, actor: nil)
      raise Error, "Please give a reason" if reason.blank?
      raise Error, "Bookings can only be cancelled before vendor confirmation" unless Booking::CANCELLABLE.include?(booking.aasm.current_state)

      Booking.transaction do
        booking.live_assignments.each do |a|
          a.payouts.where(status: "due").destroy_all
          Assignment::Workflow.release!(a, status: "expired", reason: "Booking cancelled", reassign: false)
        end
        refunded = booking.payments.where(status: "verified").sum(:amount_paise)
        booking.payments.where(status: "verified").find_each(&:refund!)
        booking.reload.cancel_reason = reason
        booking.cancel!
        Invoices::Issuer.credit_note!(booking, amount_paise: refunded, reason: "Refund on cancellation: #{reason}") if refunded.positive?
      end
      flag_paid_advances(booking)
      booking
    end

    # Advances already approved/paid to a vendor can't be silently deleted — tell finance.
    def self.flag_paid_advances(booking)
      settled = VendorPayout.where(assignment_id: booking.assignments.select(:id), status: %w[approved paid received])
      return unless settled.exists?
      Notifier.notify(Notifier.finance, kind: "payout", title: "Cancelled booking #{booking.number} has vendor advances to recover",
                      body: "#{Inr.format(settled.sum(:amount_paise))} approved or paid", url: "/admin/bookings/#{booking.to_param}", email: true)
    end
  end
end
