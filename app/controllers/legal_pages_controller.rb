class LegalPagesController < PublicController
  def show
    @page = LegalPage.published.find_by!(slug: params[:id])
    @pages = LegalPage.published.order(:title)
  end
end
