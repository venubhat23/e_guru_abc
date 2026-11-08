FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
  end

  factory :product do
    category
    sequence(:sku) { |n| "SKU-#{n}" }
    sequence(:name) { |n| "Product #{n}" }
    hsn_code { "4820" }
    gst_rate { 18 }
  end

  factory :package do
    occasion
    sequence(:name) { |n| "Package #{n}" }
    min_qty { 1 }
    after(:build) do |pkg|
      pkg.package_items.build(product: create(:product, gst_rate: 12), quantity: 1) if pkg.package_items.empty?
    end
  end

  factory :vendor_region do
    vendor
    state { "Karnataka" }
  end

  factory :vendor_offer do
    vendor
    association :offerable, factory: :package
    vendor_price_paise { 1000_00 }
    moq { 1 }
    capacity_per_week { 100 }
    lead_time_days { 5 }
    advance_pct { 30 }
  end

  factory :employee do
    company
    sequence(:emp_code) { |n| "E#{n}" }
    sequence(:name) { |n| "Employee #{n}" }
    city { "Bengaluru" }
    state { "Karnataka" }
    pincode { "560001" }
    address { "1 MG Road" }
    tshirt_size { "M" }
  end
end
