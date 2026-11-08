# All vendor offers for one product/package: price, MOQ, capacity left this week, lead time, regions, terms, rating, margin.
class Admin::OffersMatrixController < Admin::BaseController
  def show
    authorize :report, :show?
    @packages = Package.ordered
    @products = Product.approved.ordered
    @item = params[:item].to_s.start_with?("prd-") ? Product.find_by(id: params[:item].delete_prefix("prd-")) : Package.find_by(id: params[:item].to_s.delete_prefix("pkg-")) || @packages.first
    return unless @item
    @calc = Pricing::Calculator.new
    @hr_price = @calc.catalogue_price(@item)
    @offers = @item.vendor_offers.includes(vendor: :regions).sort_by { |o| [ o.active? && o.vendor.approved? ? 0 : 1, o.vendor_price_paise ] }
    @week = Date.current
  end
end
