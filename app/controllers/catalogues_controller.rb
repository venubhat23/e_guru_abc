# Downloadable product catalogue PDF (no prices — pricing is always quoted).
class CataloguesController < PublicController
  def show
    pdf = Pdf::CataloguePdf.new(Category.ordered, Product.sellable.includes(:category).ordered).render
    send_data pdf, filename: "avighna-egiftmitra-catalogue.pdf", type: "application/pdf", disposition: "inline"
  end
end
