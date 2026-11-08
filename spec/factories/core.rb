FactoryBot.define do
  factory :company do
    sequence(:legal_name) { |n| "Company #{n} Private Limited" }
    state { "Karnataka" }
  end

  factory :vendor do
    sequence(:business_name) { |n| "Vendor #{n}" }
    status { "approved" }
  end

  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "Password@123" }
    role { "super_admin" }
    email_verified_at { Time.current }

    trait(:super_admin) { role { "super_admin" } }
    trait(:ops) { role { "ops_admin" } }
    trait(:finance) { role { "finance_admin" } }
    trait(:unverified) { email_verified_at { nil } }

    factory :hr_admin do
      role { "hr_admin" }
      company
    end
    factory :hr_member do
      role { "hr_member" }
      company
    end
    factory :vendor_owner do
      role { "vendor_owner" }
      vendor
    end
  end

  factory :occasion do
    sequence(:name) { |n| "Occasion #{n}" }
    tagline { "Lovely gifts" }
    from_price_paise { 899_00 }
  end

  factory :lead do
    name { "Asha Verma" }
    sequence(:work_email) { |n| "asha#{n}@acme.example" }
    phone { "+91 98765 43210" }
    company_name { "Acme Corp" }
    employee_count { 200 }
    budget_per_employee_paise { 1500_00 }
    consent { true }
    occasion
  end

  factory :faq do
    question { "Is it good?" }
    answer { "Yes." }
  end

  factory :legal_page do
    title { "Terms of Service" }
    slug { "terms-of-service" }
    body { "## Hello\n\nSome **terms**." }
  end
end
