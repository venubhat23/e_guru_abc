module Payouts
  class Workflow
    class Error < StandardError; end

    def self.approve!(payout, by:, penalty_paise: 0, penalty_reason: nil)
      raise Error, "Balance payouts are blocked while the booking is disputed" unless payout.payable?
      payout.assign_attributes(penalty_paise: penalty_paise.to_i, penalty_reason:, approved_by: by)
      payout.approve!
    end

    def self.pay!(payout, utr:)
      raise Error, "UTR reference is required" if utr.blank?
      payout.utr = utr.strip
      payout.mark_paid!
    end

    def self.receive!(payout)
      payout.mark_received!
      Bookings::Completer.call(payout.assignment.booking)
    end
  end
end
