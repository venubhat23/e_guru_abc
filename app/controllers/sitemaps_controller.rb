class SitemapsController < PublicController
  def show
    @occasions = Occasion.active.ordered
    @legal_pages = LegalPage.published
    respond_to { |f| f.xml }
  end
end
