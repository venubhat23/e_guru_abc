require "rails_helper"

RSpec.describe "Public website" do
  let!(:occasion) { create(:occasion, name: "Diwali", slug: "diwali") }
  let!(:page) { create(:legal_page) }

  it "renders every public page" do
    [ "/", "/how-it-works", "/gifts/diwali", "/contact", "/become-a-vendor", "/legal/terms-of-service", "/session/new" ].each do |path|
      get path
      expect(response).to have_http_status(:ok), "#{path} returned #{response.status}"
    end
  end

  it "includes SEO meta tags" do
    get "/gifts/diwali"
    expect(response.body).to include('<meta name="description"', 'property="og:title"', "Diwali corporate gifts")
  end

  it "serves a sitemap with occasions and legal pages" do
    get "/sitemap.xml"
    expect(response.media_type).to eq("application/xml")
    expect(response.body).to include("/gifts/diwali", "/legal/terms-of-service")
  end

  it "hides inactive occasions and unpublished legal pages" do
    occasion.update!(active: false)
    page.update!(published: false)
    get "/gifts/diwali"
    expect(response).to have_http_status(:not_found)
    get "/legal/terms-of-service"
    expect(response).to have_http_status(:not_found)
  end

  it "renders legal page Markdown safely" do
    page.update!(body: "## Heading\n\n<script>alert(1)</script>**bold**")
    get "/legal/terms-of-service"
    expect(response.body).to include("<strong>bold</strong>")
    expect(response.body).not_to include("<script>alert(1)</script>")
  end
end
