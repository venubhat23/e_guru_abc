class PagesController < PublicController
  def home
    @occasions = Occasion.active.ordered
    @faqs = Faq.for("public").limit(8)
    @categories = Category.ordered
    @products = Product.sellable.includes(:category).with_attached_images.ordered
    @lead = Lead.new
  end

  def how_it_works; end
end
