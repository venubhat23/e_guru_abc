module Pdf
  # 2 × 5 address labels per A4 page.
  class LabelsPdf < Base
    def initialize(assignment) = (@assignment = assignment)
    def title = "Labels #{@assignment.booking.number}"

    def render
      w = (bounds.width - 12) / 2
      h = (bounds.height - 48) / 5
      @assignment.recipients.order(:name).each_slice(10).with_index do |page, pi|
        start_new_page if pi.positive?
        page.each_with_index do |r, i|
          x = (i % 2) * (w + 12)
          y = bounds.height - (i / 2) * (h + 12)
          bounding_box([ x, y ], width: w, height: h) do
            stroke_color "CBD5E1"
            stroke_rounded_rectangle [ 0, h ], w, h, 8
            indent(12, 12) do
              move_down 12
              text r.name, size: 12, style: :bold, color: PLUM
              text r.phone.to_s, color: MUTED
              move_down 4
              text r.address.to_s, size: 9
              text "#{r.city} – #{r.pincode}", size: 10, style: :bold
              text r.state.to_s, size: 9
              move_down 4
              text "Ref #{@assignment.booking.number} · #{r.tshirt_size}", size: 7, color: MUTED
            end
          end
        end
      end
      document.render
    end
  end
end
