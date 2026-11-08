# HR price = vendor price × (1 + markup), rounded UP to the configured step.
# Markup priority: company override > product override > category (or parent) override > platform default.
module Pricing
  class Calculator
    Breakdown = Struct.new(:vendor_paise, :markup_pct, :markup_source, :raw_paise, :hr_paise, :margin_paise, keyword_init: true) do
      def margin_pct = hr_paise.zero? ? 0 : (margin_paise * 100.0 / hr_paise).round(1)
    end

    def initialize(company: nil)
      @company = company
    end

    def markup(product: nil, category: nil)
      category ||= product&.category
      return [ @company.markup_override_pct, "company" ] if @company&.markup_override_pct.present?
      return [ product.markup_override_pct, "product" ] if product&.markup_override_pct.present?
      return [ category.markup_override_pct, "category" ] if category&.markup_override_pct.present?
      return [ category.parent.markup_override_pct, "parent category" ] if category&.parent&.markup_override_pct.present?
      [ BigDecimal(Setting[:default_markup_pct].to_s), "default" ]
    end

    def breakdown(vendor_paise, product: nil, category: nil)
      pct, source = markup(product:, category:)
      raw = (BigDecimal(vendor_paise.to_s) * (1 + BigDecimal(pct.to_s) / 100))
      hr = round_up(raw)
      Breakdown.new(vendor_paise:, markup_pct: pct.to_d, markup_source: source, raw_paise: raw.round.to_i, hr_paise: hr, margin_paise: hr - vendor_paise)
    end

    def hr_price(vendor_paise, **) = breakdown(vendor_paise, **).hr_paise

    # Catalogue price: based on the lowest active offer from an approved vendor.
    def lowest_offer(offerable) = offerable.vendor_offers.active.from_approved_vendors.order(:vendor_price_paise).first

    def catalogue_price(offerable)
      offer = lowest_offer(offerable)
      offer && hr_price(offer.vendor_price_paise, **offerable_context(offerable))
    end

    def offerable_context(offerable) = offerable.is_a?(Product) ? { product: offerable } : {}

    private

    def round_up(raw_paise)
      step = Setting[:price_rounding_step_rupees].to_i * 100
      return raw_paise.ceil.to_i if step <= 0
      ((raw_paise / step).ceil * step).to_i
    end
  end
end
