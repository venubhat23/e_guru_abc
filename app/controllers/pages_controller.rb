class PagesController < PublicController
  def home
    @occasions = Occasion.active.ordered
    @faqs = Faq.for("public").limit(8)
    @lead = Lead.new
  end

  def how_it_works; end
end
