require "rails_helper"

RSpec.describe "Public catalogue", type: :request do
  let!(:product) { create(:product, name: "Brandable Steel Bottle") }

  it "lists sellable products without prices and filters by category" do
    get products_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Brandable Steel Bottle", "Request quote")
    expect(response.body).not_to include("₹")

    get products_path(category: product.category.slug)
    expect(response.body).to include("Brandable Steel Bottle")
  end

  it "serves a downloadable catalogue PDF" do
    get catalogue_path
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
  end

  it "pre-fills the contact form from a product quote link" do
    get new_contact_path(message: "Interested in: Brandable Steel Bottle")
    expect(response.body).to include("Interested in: Brandable Steel Bottle")
  end
end
