module Pdf
  # HR-facing. Contains HR prices only — never vendor names or vendor prices.
  class ProformaPdf < Base
    def initialize(booking) = (@booking = booking)
    def title = "Proforma #{@booking.number}"

    def render
      b = @booking
      header("Proforma invoice", number: "PF-#{b.number}", date: (b.submitted_at || b.created_at).to_date)
      parties("Supplier", platform_lines, "Bill to", company_lines(b.company))
      text "Occasion: #{b.occasion&.name || '—'}   ·   Delivery: #{b.delivery_mode_label}   ·   Requested by: #{b.requested_delivery_on.strftime('%d %b %Y')}", color: MUTED
      move_down 10
      rows = [ [ "Item", "HSN", "Qty", "Rate", "Amount" ] ]
      rows << [ b.bookable_name, b.bookable.try(:hsn_code).to_s, b.quantity, money(b.unit_price_paise), money(b.hr_subtotal_paise) ]
      rows << [ "Delivery charges", "996812", "", "", money(b.delivery_charge_paise) ] if b.delivery_charge_paise.positive?
      table_style(rows, [ 230, 60, 50, 90, nil ], align_right: [ 2, 3, 4 ])
      totals([ [ "Taxable value", money(b.taxable_paise) ], *gst_rows(b, b.gst_rate), [ "Total payable", money(b.total_paise) ] ])
      footer_note("This is a proforma invoice, not a tax invoice. Prices are locked as of submission. The GST tax invoice is issued on completion.")
      document.render
    end
  end
end
