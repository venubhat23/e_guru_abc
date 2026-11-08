require "rails_helper"

RSpec.describe "Admin website content" do
  let(:admin) { create(:user, :super_admin) }
  let!(:page) { create(:legal_page) }

  before { sign_in(admin) }

  it "edits a legal page and the public site shows it" do
    patch admin_legal_page_path(page), params: { legal_page: { body: "## Updated clause\n\nNew text." } }
    expect(response).to redirect_to(admin_legal_pages_path)
    get legal_page_path(page)
    expect(response.body).to include("Updated clause")
    expect(page.versions.last.whodunnit).to eq(admin.id.to_s)
  end

  it "creates FAQs and occasions" do
    post admin_faqs_path, params: { faq: { question: "Do you ship to Leh?", answer: "Yes", audience: "public", active: "1" } }
    expect(Faq.last.question).to eq("Do you ship to Leh?")
    post admin_occasions_path, params: { occasion: { name: "Women's Day", theme: "rani", from_price_rupees: "799", highlights_text: "Spa kit\nChocolates", active: "1" } }
    occasion = Occasion.last
    expect(occasion.slug).to eq("women-s-day")
    expect(occasion.from_price_paise).to eq(799_00)
    expect(occasion.highlights).to eq([ "Spa kit", "Chocolates" ])
  end

  it "saves settings as super admin" do
    patch admin_settings_path, params: { settings: { default_markup_pct: "45", assignment_mode: "manual" } }
    expect(Setting[:default_markup_pct]).to eq(45)
    expect(Setting[:assignment_mode]).to eq("manual")
  end

  it "validates settings" do
    patch admin_settings_path, params: { settings: { default_markup_pct: "abc" } }
    expect(flash[:alert]).to match(/whole number/)
  end
end
