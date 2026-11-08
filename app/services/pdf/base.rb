require "prawn"
require "prawn/table"

module Pdf
  class Base
    include Prawn::View
    BRAND = "F96A12"
    PLUM = "24103A"
    MUTED = "64748B"

    def document
      @document ||= Prawn::Document.new(page_size: "A4", margin: 36, info: { Title: title, Creator: "Avighna eGiftMitra" }).tap do |doc|
        doc.font_families.update("DejaVu" => { normal: font_path("DejaVuSans.ttf"), bold: font_path("DejaVuSans-Bold.ttf") })
        doc.font "DejaVu"
        doc.font_size 9
      end
    end

    def money(paise) = Inr.format(paise, decimals: true)

    def header(doc_title, number:, date:)
      bounding_box([ 0, cursor ], width: bounds.width) do
        fill_color BRAND
        fill_rounded_rectangle [ 0, cursor ], 28, 28, 6
        fill_color "FFFFFF"
        draw_text "A", at: [ 9, cursor - 19 ], size: 14, style: :bold
        fill_color PLUM
        draw_text "Avighna eGiftMitra", at: [ 36, cursor - 18 ], size: 16, style: :bold
        text_box doc_title.upcase, at: [ bounds.width - 250, cursor ], width: 250, align: :right, size: 16, style: :bold, color: PLUM
        text_box "#{number}\n#{date.strftime('%d %b %Y')}", at: [ bounds.width - 250, cursor - 22 ], width: 250, align: :right, color: MUTED
        move_down 52
      end
      fill_color "000000"
      stroke_color "E2E8F0"
      stroke_horizontal_rule
      move_down 14
    end

    def parties(left_title, left_lines, right_title, right_lines)
      top = cursor
      [ [ 0, left_title, left_lines ], [ bounds.width / 2 + 10, right_title, right_lines ] ].each do |x, t, lines|
        bounding_box([ x, top ], width: bounds.width / 2 - 10) do
          text t.upcase, size: 7, style: :bold, color: MUTED, character_spacing: 1
          move_down 4
          lines.compact_blank.each_with_index { |l, i| text l.to_s, style: i.zero? ? :bold : :normal, color: i.zero? ? PLUM : "333333" }
        end
      end
      move_down 16
    end

    def table_style(data, widths, align_right: [])
      table(data, header: true, width: bounds.width, column_widths: widths, cell_style: { borders: [ :bottom ], border_color: "E2E8F0", padding: [ 6, 6 ] }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "FFF6ED"
        t.row(0).text_color = PLUM
        align_right.each { |c| t.column(c).align = :right }
      end
    end

    def totals(rows)
      move_down 8
      bounding_box([ bounds.width - 240, cursor ], width: 240) do
        rows.each_with_index do |(label, value), i|
          last = i == rows.size - 1
          text_box label, at: [ 0, cursor ], width: 140, style: last ? :bold : :normal, color: last ? PLUM : "333333"
          text_box value, at: [ 140, cursor ], width: 100, align: :right, style: last ? :bold : :normal, color: last ? PLUM : "333333"
          move_down 15
        end
      end
    end

    def footer_note(textline)
      move_down 20
      text textline, size: 7.5, color: MUTED
    end

    def platform_lines
      [ Setting[:platform_legal_name], Setting[:platform_address], "GSTIN: #{Setting[:platform_gstin]}", "State: #{Setting[:platform_state]}" ]
    end

    def company_lines(company)
      [ company.legal_name, company.billing_address, ("GSTIN: #{company.gstin}" if company.gstin), "Place of supply: #{company.state}" ]
    end

    def gst_rows(record, rate)
      rows = []
      if record.igst_paise.positive?
        rows << [ "IGST @ #{rate.to_f.round(2)}%", money(record.igst_paise) ]
      else
        rows << [ "CGST @ #{(rate / 2).to_f.round(2)}%", money(record.cgst_paise) ]
        rows << [ "SGST @ #{(rate / 2).to_f.round(2)}%", money(record.sgst_paise) ]
      end
      rows
    end

    private

    def font_path(name) = Rails.root.join("vendor/fonts", name).to_s
  end
end
