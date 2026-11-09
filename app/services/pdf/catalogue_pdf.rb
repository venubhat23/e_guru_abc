module Pdf
  # Public product catalogue. Deliberately has no prices: every order is quoted.
  class CataloguePdf < Base
    def initialize(categories, products) = (@categories, @products = categories, products)
    def title = "Corporate gifting catalogue"

    def render
      header("Catalogue", number: "Corporate gifting collection", date: Date.current)
      text "Curated corporate gifts, fully brandable and delivered anywhere in India.", size: 11, color: PLUM, style: :bold
      text "Pricing depends on quantity, branding and delivery — request a custom quote at #{Setting[:support_email]} or #{Setting[:support_phone]}.", color: MUTED
      move_down 14
      by_cat = @products.group_by(&:category)
      @categories.each do |cat|
        items = by_cat[cat]
        next if items.blank?
        start_new_page if cursor < 120
        fill_color BRAND
        text cat.name.upcase, size: 11, style: :bold, character_spacing: 1
        fill_color "000000"
        move_down 4
        rows = [ [ "SKU", "Product", "Details", "Branding" ] ]
        items.each { |p| rows << [ p.sku, p.name, p.description.to_s.truncate(110), p.brandable? ? "Logo / custom print" : "—" ] }
        table_style(rows, [ 60, 150, nil, 90 ])
        move_down 14
      end
      footer_note("#{Setting[:platform_legal_name]} · #{Setting[:support_email]} · #{Setting[:support_phone]} · Images and availability may vary by city and season.")
      document.render
    end
  end
end
