module Payouts
  class Scheduler
    # Advance = vendor_total × advance_pct, due when the vendor accepts.
    def self.on_accept(assignment)
      amount = assignment.advance_paise
      return if amount.zero?
      VendorPayout.create!(vendor: assignment.vendor, assignment:, kind: "advance", gross_paise: amount, amount_paise: amount, due_on: Date.current)
    end

    # Balance = vendor_total − advance, due on delivery or after credit days (penalties deducted at approval).
    def self.on_delivered(assignment)
      advance = assignment.payouts.find_by(kind: "advance")&.gross_paise.to_i
      balance = assignment.vendor_total_paise - advance
      delivered_on = (assignment.delivered_at || Time.current).to_date
      due = assignment.balance_terms == "credit" ? delivered_on + assignment.credit_days : delivered_on
      VendorPayout.create!(vendor: assignment.vendor, assignment:, kind: "balance", gross_paise: balance, amount_paise: balance, due_on: due)
    end
  end
end
