module Pdf
  # Tax invoice or credit note issued to the client company (no vendor data).
  class InvoicePdf < Base
    def initialize(invoice) = (@invoice = invoice)
    def title = "#{@invoice.kind_label} #{@invoice.number}"

    def render
      inv = @invoice
      b = inv.booking
      header(inv.kind == "credit_note" ? "Credit note" : "Tax invoice", number: inv.number, date: inv.issued_on)
      parties("Supplier", platform_lines, "Recipient", company_lines(inv.company))
      text "Booking #{b.number}#{" · against #{inv.original_invoice.number}" if inv.original_invoice}#{" · #{inv.reason}" if inv.reason.present?}", color: MUTED
      move_down 10
      rows = [ [ "Description", "HSN/SAC", "Qty", "Taxable value" ] ]
      if inv.kind == "credit_note"
        rows << [ "Credit against booking #{b.number}", b.bookable.try(:hsn_code).to_s, "", money(inv.taxable_paise) ]
      else
        rows << [ "#{b.bookable_name} (#{b.occasion&.name})", b.bookable.try(:hsn_code).to_s, b.quantity, money(b.hr_subtotal_paise) ]
        rows << [ "Delivery charges", "996812", "", money(b.delivery_charge_paise) ] if b.delivery_charge_paise.positive?
      end
      table_style(rows, [ 260, 80, 50, nil ], align_right: [ 2, 3 ])
      totals([ [ "Taxable value", money(inv.taxable_paise) ], *gst_rows(inv, b.gst_rate), [ inv.kind == "credit_note" ? "Total credit" : "Invoice total", money(inv.total_paise) ] ])
      footer_note("Financial year #{inv.financial_year}. Computer-generated document; no signature required. Supply is a mixed supply taxed at the highest applicable rate.")
      document.render
    end
  end
end
