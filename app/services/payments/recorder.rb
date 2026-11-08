module Payments
  class Recorder
    def self.record_offline!(booking:, method:, amount_paise:, reference:, proof: nil)
      payment = booking.payments.create!(method:, amount_paise:, reference:)
      payment.proof.attach(proof) if proof
      payment
    end

    def self.verify!(payment, by:)
      Payment.transaction do
        payment.verified_by = by
        payment.verify!
        Bookings::PaymentApplier.call(payment.booking)
      end
    end

    def self.reject!(payment, by:, notes:)
      payment.update!(verified_by: by, notes:)
      payment.fail!
    end
  end
end
