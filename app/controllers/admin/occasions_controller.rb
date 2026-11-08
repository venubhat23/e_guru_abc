class Admin::OccasionsController < Admin::ContentController
  private

  def model = Occasion
  def order_by = %i[position name]

  def permitted
    attrs = params.require(:occasion).permit(:name, :slug, :tagline, :description, :emoji, :theme, :season_starts_on,
                                             :season_ends_on, :from_price_rupees, :highlights_text, :position, :active)
    attrs[:from_price_paise] = Inr.to_paise(attrs.delete(:from_price_rupees)) if attrs.key?(:from_price_rupees)
    attrs[:highlights] = attrs.delete(:highlights_text).to_s.lines.map(&:strip).compact_blank if attrs.key?(:highlights_text)
    attrs
  end
end
