module Invoices
  class Issuer
    def self.tax_invoice!(booking)
      booking.tax_invoice || begin
        number, fy = DocumentSequence.next_number!("tax_invoice")
        booking.invoices.create!(kind: "tax_invoice", company: booking.company, number:, financial_year: fy, issued_on: Date.current,
                                 taxable_paise: booking.taxable_paise, cgst_paise: booking.cgst_paise, sgst_paise: booking.sgst_paise,
                                 igst_paise: booking.igst_paise, total_paise: booking.total_paise)
      end
    end

    # Credit note for an amount (GST components scaled proportionally to the booking).
    def self.credit_note!(booking, amount_paise:, reason:)
      ratio = booking.total_paise.zero? ? 0 : BigDecimal(amount_paise.to_s) / booking.total_paise
      cgst, sgst, igst = [ booking.cgst_paise, booking.sgst_paise, booking.igst_paise ].map { (ratio * _1).round.to_i }
      number, fy = DocumentSequence.next_number!("credit_note")
      booking.invoices.create!(kind: "credit_note", company: booking.company, original_invoice: booking.tax_invoice, number:, financial_year: fy,
                               issued_on: Date.current, taxable_paise: amount_paise - cgst - sgst - igst, cgst_paise: cgst, sgst_paise: sgst,
                               igst_paise: igst, total_paise: amount_paise, reason:)
    end
  end
end
