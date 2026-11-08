class Admin::CatalogueController < Admin::BaseController
  def index
    @categories = policy_scope(Category).ordered
    @product_counts = Product.group(:category_id).count
    @packages = policy_scope(Package).includes(:occasion, package_items: :product).ordered
    @pending = Product.pending_review.includes(:proposed_by_vendor, :category)
    @calc = Pricing::Calculator.new
  end
end
