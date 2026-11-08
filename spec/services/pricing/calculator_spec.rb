require "rails_helper"

RSpec.describe Pricing::Calculator do
  let(:category) { create(:category) }
  let(:product) { create(:product, category:) }

  it "applies the default 40% markup and rounds UP to the nearest ₹10" do
    b = described_class.new.breakdown(1001_00, product:)
    expect(b.markup_pct).to eq(40)
    expect(b.markup_source).to eq("default")
    expect(b.raw_paise).to eq(1401_40)
    expect(b.hr_paise).to eq(1410_00)
    expect(b.margin_paise).to eq(409_00)
  end

  it "resolves markup by priority: company > product > category > default" do
    company = create(:company, markup_override_pct: 25)
    category.update!(markup_override_pct: 50)
    expect(described_class.new.markup(product:)).to eq([ 50, "category" ])
    product.update!(markup_override_pct: 30)
    expect(described_class.new.markup(product:)).to eq([ 30, "product" ])
    expect(described_class.new(company:).markup(product:)).to eq([ 25, "company" ])
  end

  it "falls back to the parent category's override" do
    parent = create(:category, markup_override_pct: 60)
    category.update!(parent:)
    expect(described_class.new.markup(product:)).to eq([ 60, "parent category" ])
  end

  it "respects the rounding setting" do
    Setting[:price_rounding_step_rupees] = 50
    expect(described_class.new.hr_price(1000_00, product:)).to eq(1400_00)
    expect(described_class.new.hr_price(1001_00, product:)).to eq(1450_00)
    Setting[:price_rounding_step_rupees] = 0
    expect(described_class.new.hr_price(1001_00, product:)).to eq(1401_40)
  end

  it "prices the catalogue from the lowest ACTIVE offer of an APPROVED vendor" do
    package = create(:package)
    vendor_with_offer(package:, price: 900_00)
    create(:vendor_offer, vendor: create(:vendor, status: "pending"), offerable: package, vendor_price_paise: 500_00)
    vendor_with_offer(package:, price: 700_00, active: false)
    expect(described_class.new.catalogue_price(package)).to eq(1260_00)
  end
end
