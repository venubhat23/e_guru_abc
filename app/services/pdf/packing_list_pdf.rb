module Pdf
  # Vendor-facing. Recipients, sizes and card messages — no HR prices.
  class PackingListPdf < Base
    def initialize(assignment) = (@assignment = assignment)
    def title = "Packing list #{@assignment.booking.number}"

    def render
      a = @assignment
      header("Packing list", number: "#{a.booking.number}-A#{a.id}", date: Date.current)
      text "#{a.booking.bookable_name} · #{a.quantity} kits · deliver by #{a.booking.requested_delivery_on.strftime('%d %b %Y')}", style: :bold, color: PLUM
      if (items = a.booking.bookable.try(:package_items))
        move_down 6
        text "Each kit contains: " + items.map { "#{_1.quantity}× #{_1.product.name}" }.join(", "), color: MUTED
      end
      if (msg = a.booking.personalisation["card_message"]).present?
        move_down 4
        text "Card message template: #{msg}", color: MUTED
      end
      move_down 10
      rows = [ [ "#", "Recipient", "Size", "Card message", "City / Pincode" ] ]
      a.recipients.order(:name).each_with_index { |r, i| rows << [ i + 1, r.name, r.tshirt_size.to_s, r.card_message.to_s, "#{r.city} #{r.pincode}" ] }
      table_style(rows, [ 24, 130, 40, 200, nil ])
      document.render
    end
  end
end
