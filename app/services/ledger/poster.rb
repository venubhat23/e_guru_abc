# Posts platform economics for a completed booking. Must run inside the completion transaction.
#   revenue           = hr_subtotal − vendor_subtotal
#   marketing_reserve = marketing_pct × vendor_subtotal
#   gateway_fees      = sum of gateway fees on verified payments
module Ledger
  class Poster
    def self.post!(booking)
      raise ArgumentError, "Booking must be completed" unless booking.completed?
      return booking.ledger_entries if booking.ledger_entries.exists?

      vendor = booking.vendor_subtotal_paise
      amounts = {
        "revenue" => booking.hr_subtotal_paise - vendor,
        "marketing_reserve" => (BigDecimal(vendor.to_s) * Setting[:marketing_reserve_pct].to_i / 100).round.to_i,
        "gateway_fees" => booking.payments.where(status: %w[verified refunded]).sum(:gateway_fee_paise)
      }
      amounts.each do |account, amount|
        booking.ledger_entries.create!(account:, amount_paise: amount, posted_at: Time.current, memo: "#{booking.number} completion")
      end
      booking.ledger_entries
    end

    def self.totals(scope = LedgerEntry.all)
      sums = scope.group(:account).sum(:amount_paise)
      revenue, marketing, fees = sums.values_at("revenue", "marketing_reserve", "gateway_fees").map(&:to_i)
      { revenue:, marketing_reserve: marketing, gateway_fees: fees, net_contribution: revenue - marketing - fees }
    end
  end
end
