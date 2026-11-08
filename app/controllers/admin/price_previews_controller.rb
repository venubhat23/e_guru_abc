# Price preview tool: see exactly how an HR price is built for any company and item.
class Admin::PricePreviewsController < Admin::BaseController
  def show
    authorize :report, :show?
    @companies = Company.order(:legal_name)
    @products = Product.approved.ordered
    @company = Company.find_by(id: params[:company_id])
    @item = params[:item].to_s.start_with?("pkg-") ? Package.find_by(id: params[:item].delete_prefix("pkg-")) : Product.find_by(id: params[:item].to_s.delete_prefix("prd-"))
    @calc = Pricing::Calculator.new(company: @company)
    return unless @item
    offer = @calc.lowest_offer(@item)
    @vendor_paise = params[:vendor_price].present? ? Inr.to_paise(params[:vendor_price]) : offer&.vendor_price_paise
    @breakdown = @vendor_paise && @calc.breakdown(@vendor_paise, **@calc.offerable_context(@item))
  end
end
