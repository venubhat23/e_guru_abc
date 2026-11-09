# Public product catalogue. Shows what we can source and brand — never prices.
class ProductsController < PublicController
  def index
    @categories = Category.ordered
    @category = @categories.find { _1.slug == params[:category] }
    @products = Product.sellable.includes(:category).with_attached_images.ordered
    @products = @products.where(category: @category) if @category
  end
end
