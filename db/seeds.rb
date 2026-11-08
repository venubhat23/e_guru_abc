ActionMailer::Base.perform_deliveries = false
ActiveJob::Base.queue_adapter = :inline
# Idempotent seeds: safe to run repeatedly (bin/rails db:seed).
require "faker"
Faker::Config.locale = "en-IND"
PaperTrail.request.whodunnit = nil

PASSWORD = ENV.fetch("SEED_PASSWORD", "Password@123")
puts "Seeding Avighna eGiftMitra…"

def seed_user(email, name:, role:, company: nil, vendor: nil, phone: nil)
  User.find_or_initialize_by(email_address: email).tap do |u|
    u.assign_attributes(name:, role:, company:, vendor:, phone:, active: true, email_verified_at: u.email_verified_at || Time.current)
    u.password = PASSWORD if u.new_record?
    u.save!
  end
end

# ---------- Platform admins ----------
admin   = seed_user("admin@egiftguru.in", name: "Aarav Mehta", role: "super_admin", phone: "+919800000001")
ops     = seed_user("ops@egiftguru.in", name: "Priya Nair", role: "ops_admin", phone: "+919800000002")
_finance = seed_user("finance@egiftguru.in", name: "Rohan Iyer", role: "finance_admin", phone: "+919800000003")

# ---------- Occasions ----------
year = Date.current.year
occasions = [
  { name: "Diwali", slug: "diwali", emoji: "🪔", theme: "saffron", position: 1, from: 899,
    tagline: "Light up every home with gifts that glow.",
    season: [ Date.new(year, 9, 15), Date.new(year, 11, 15) ],
    description: "Our Diwali collection blends tradition with modern taste — premium dry fruits, artisanal sweets, handcrafted diyas and curated hampers that make every employee feel celebrated during the festival of lights.",
    highlights: [ "Premium dry fruit boxes", "Organic mithai from local halwais", "Hand-painted diyas & decor", "Personalised greeting cards", "Eco-friendly packaging" ] },
  { name: "New Year", slug: "new-year", emoji: "🎆", theme: "plum", position: 2, from: 699,
    tagline: "Kick off the year with goodies they'll use daily.",
    season: [ Date.new(year, 12, 1), Date.new(year, 12, 31) ],
    description: "Start the year on a high note with productivity kits, premium diaries, branded drinkware and tech accessories your team will actually use.",
    highlights: [ "2027 planners & diaries", "Insulated steel bottles", "Wireless earphones", "Desk essentials", "Logo branding" ] },
  { name: "Birthday", slug: "birthday", emoji: "🎂", theme: "rani", position: 3, from: 499,
    tagline: "Make every birthday feel personal — automatically.",
    season: [ nil, nil ],
    description: "Set it and forget it. Birthday gifts can be scheduled automatically so no employee's special day is missed, with a personalised card from the team.",
    highlights: [ "Gourmet chocolates", "Personalised mugs", "Name-printed cards", "Automated scheduling", "Doorstep delivery" ] },
  { name: "Onboarding", slug: "onboarding", emoji: "🎒", theme: "emerald", position: 4, from: 1299,
    tagline: "Welcome kits that make day one unforgettable.",
    season: [ nil, nil ],
    description: "First impressions matter. Our onboarding kits arrive before day one with branded T-shirts, bottles, diaries and a warm welcome note — auto-drafted whenever you add a new joiner.",
    highlights: [ "Branded T-shirt in the right size", "Steel water bottle", "Premium diary & pen", "Welcome card from leadership", "Laptop sleeve or backpack" ] },
  { name: "Festival", slug: "festival", emoji: "🎉", theme: "sky", position: 5, from: 599,
    tagline: "Pongal, Onam, Holi, Eid, Christmas — we've got them all.",
    season: [ nil, nil ],
    description: "India celebrates all year. Our regional festival hampers respect local traditions — from Onam sadya kits to Holi organic colour boxes and Christmas plum cakes.",
    highlights: [ "Region-specific hampers", "Organic sweets & snacks", "Festive décor", "Multilingual cards", "Pan-India delivery" ] }
]
occasion_records = occasions.map do |o|
  Occasion.find_or_initialize_by(slug: o[:slug]).tap do |rec|
    rec.update!(name: o[:name], emoji: o[:emoji], theme: o[:theme], position: o[:position], tagline: o[:tagline],
                description: o[:description], highlights: o[:highlights], from_price_paise: o[:from] * 100,
                season_starts_on: o[:season][0], season_ends_on: o[:season][1], active: true)
  end
end

# ---------- FAQs ----------
[
  [ "public", "What is the minimum order quantity?", "Most packages start at 25 kits. Custom Unbox boxes start at 50. For smaller teams, talk to us — we can often help." ],
  [ "public", "Can you deliver to each employee's home?", "Yes. We deliver to individual home addresses across 19,000+ pincodes, in bulk to your offices, or let employees fill in their own address via a secure link." ],
  [ "public", "Can gifts be branded with our logo?", "Absolutely. Most products support logo printing, and every kit can include a personalised card with the employee's name and a message from leadership." ],
  [ "public", "How does GST work on invoices?", "We issue a GST tax invoice in our name. GST is charged as CGST + SGST for intra-state supply or IGST for inter-state supply, based on your billing state." ],
  [ "public", "How do I pay?", "Pay online via Razorpay (cards, UPI, net banking) or by bank transfer / purchase order with proof upload. Credit terms are available for eligible companies." ],
  [ "public", "What if a gift arrives damaged?", "Raise an issue for that recipient from your booking page within 7 days. We'll replace it or issue a credit note — no back-and-forth." ],
  [ "public", "How far in advance should we book?", "Each package shows its lead time — typically 7–14 days. For Diwali, we recommend booking 3–4 weeks ahead." ],
  [ "public", "Do you handle birthdays and onboarding automatically?", "Yes. Set a package and timing once, and we'll auto-draft bookings for birthdays, work anniversaries and new joiners." ],
  [ "vendor", "Is there a fee to join?", "No. Joining is free. You set your own prices; we add our margin on top when selling to companies." ],
  [ "vendor", "When do I get paid?", "An advance becomes due when you accept an order (as per your advance %), and the balance on delivery or after your agreed credit days." ],
  [ "vendor", "Can I choose where I deliver?", "Yes. You choose the states, cities and pincode prefixes you serve, and only receive orders you can fulfil." ],
  [ "vendor", "Do I need FSSAI?", "Only if you supply food items such as sweets, chocolates or dry fruits." ]
].each_with_index do |(audience, q, a), i|
  Faq.find_or_initialize_by(question: q).update!(answer: a, audience:, position: i + 1, active: true)
end

# ---------- Legal pages ----------
{
  "terms-of-service" => [ "Terms of Service", "The rules for using Avighna eGiftMitra as a client company." ],
  "privacy-policy" => [ "Privacy Policy", "How we collect, use and protect personal data under India's DPDP Act, 2023." ],
  "refund-policy" => [ "Refund & Cancellation Policy", "When you can cancel, how refunds work and what happens if something goes wrong." ],
  "shipping-policy" => [ "Shipping & Delivery Policy", "Delivery coverage, modes, timelines and tracking." ],
  "vendor-terms" => [ "Vendor Terms", "The agreement between Avighna eGiftMitra and its supplier partners." ]
}.each do |slug, (title, summary)|
  page = LegalPage.find_or_initialize_by(slug:)
  page.update!(title:, summary:, body: Rails.root.join("db/seeds/legal/#{slug}.md").read, effective_on: Date.new(2026, 4, 1), published: true) if page.new_record?
end

# ---------- Companies + HR users ----------
acme = Company.find_or_initialize_by(gstin: "29AAACA1234A1Z5")
acme.update!(legal_name: "Acme Technologies Private Limited", display_name: "Acme Technologies", pan: "AAACA1234A", state: "Karnataka",
             billing_address: "4th Floor, Prestige Tech Park\nOuter Ring Road, Marathahalli\nBengaluru 560103", shipping_address: "Same as billing",
             payment_terms: "prepaid", approval_limit_paise: 1_00_000_00)
bharat = Company.find_or_initialize_by(gstin: "27AABCB5678B1Z3")
bharat.update!(legal_name: "Bharat Retail Limited", display_name: "Bharat Retail", pan: "AABCB5678B", state: "Maharashtra",
               billing_address: "12th Floor, One BKC\nBandra Kurla Complex\nMumbai 400051", shipping_address: "Same as billing",
               payment_terms: "credit", approval_limit_paise: 10_00_000_00)
seed_user("hr@acmetech.in", name: "Kavya Sharma", role: "hr_admin", company: acme, phone: "+919811111111")
seed_user("people@acmetech.in", name: "Arjun Rao", role: "hr_member", company: acme, phone: "+919811111112")
seed_user("hr@bharatretail.in", name: "Neha Kulkarni", role: "hr_admin", company: bharat, phone: "+919822222221")
seed_user("talent@bharatretail.in", name: "Vikram Joshi", role: "hr_member", company: bharat, phone: "+919822222222")

# ---------- Vendors ----------
[
  [ "SweetCraft Foods", "vendor@sweetcraft.in", "Meera Agarwal", "08AABCS1111K1Z2", "approved" ],
  [ "PrintPerfect Merch", "vendor@printperfect.in", "Sanjay Gupta", "07AACCP2222L1Z9", "approved" ],
  [ "Kala Handicrafts", "vendor@kalahandicrafts.in", "Lakshmi Menon", "32AADCK3333M1Z4", "approved" ],
  [ "TechTreats Gadgets", "vendor@techtreats.in", "Imran Shaikh", "27AAECT4444N1Z1", "approved" ],
  [ "GreenLeaf Organics", "vendor@greenleaf.in", "Ritu Bansal", nil, "pending" ]
].each do |name, email, owner, gstin, status|
  vendor = Vendor.find_or_initialize_by(business_name: name)
  vendor.update!(email:, gstin:, pan: gstin&.slice(2, 10), phone: "+91 98#{rand(10_000_000..99_999_999)}", status:) if vendor.new_record?
  seed_user(email, name: owner, role: "vendor_owner", vendor:)
end

# ---------- Leads ----------
if Lead.count < 20
  companies = [ "Infosphere Labs", "Zenith Pharma", "Kaveri Textiles", "NovaPay Fintech", "Saffron Hotels", "Orbit Logistics",
               "Lotus Healthcare", "Indus Motors", "Peacock Media", "Banyan Capital", "Monsoon Foods", "Tiger Analytics",
               "Himalaya Steel", "Coral Software", "Ganga Agro", "Nilgiri Tea Co", "Quantum Edtech", "Mango Retail",
               "Sitar Studios", "Deccan Infra", "Pixel Forge", "Sapphire Realty", "Arcadia Insurance", "Vayu Airlines" ]
  statuses = %w[fresh fresh fresh fresh contacted contacted contacted demo_scheduled demo_scheduled proposal_sent proposal_sent won won lost]
  companies.each_with_index do |company_name, i|
    first, last = Faker::Name.first_name, Faker::Name.last_name
    status = statuses[i % statuses.size]
    created = rand(1..80).days.ago
    lead = Lead.create!(name: "#{first} #{last}", work_email: "#{first.downcase}.#{last.downcase}@#{company_name.parameterize}.com".delete("'"),
                        phone: "+91 9#{rand(100_000_000..999_999_999)}", company_name:, employee_count: [ 40, 120, 250, 500, 800, 1500, 3200 ].sample,
                        occasion: occasion_records.sample, budget_per_employee_paise: [ 500, 800, 1000, 1500, 2000, 3000 ].sample * 100,
                        message: [ "Looking for Diwali hampers for all offices.", "Need onboarding kits for ~30 joiners a month.", "Would like branded New Year gifts.", nil ].sample,
                        consent: true, status:, owner: (status == "fresh" ? nil : [ admin, ops ].sample),
                        follow_up_on: (%w[contacted demo_scheduled proposal_sent].include?(status) ? rand(-3..10).days.from_now.to_date : nil),
                        lost_reason: (status == "lost" ? "Budget too low for current season" : nil), created_at: created, updated_at: created)
    lead.activities.create!(kind: "created", body: "Lead submitted via website contact form", created_at: created)
    unless status == "fresh"
      lead.activities.create!(kind: "note", user: lead.owner, body: "Spoke to #{first}. Interested in #{lead.occasion.name} gifting for #{lead.employee_count} employees.", created_at: created + 1.day)
      lead.activities.create!(kind: "status_change", user: lead.owner, body: "Status changed from New to #{lead.status_label}", created_at: created + 2.days)
    end
  end
  # One converted lead per seeded company
  { acme => "Acme Technologies", bharat => "Bharat Retail" }.each do |company, name|
    lead = Lead.create!(name: "#{name} HR", work_email: "hr@#{name.parameterize}.example", phone: "+91 9876543210", company_name: name,
                        employee_count: 50, occasion: occasion_records.first, budget_per_employee_paise: 1500_00, consent: true,
                        status: "won", owner: ops, company:, converted_at: 30.days.ago, created_at: 40.days.ago)
    lead.activities.create!(kind: "converted", user: ops, body: "Converted to company #{company.legal_name}")
  end
end

# ---------- Notifications ----------
if admin.notifications.none?
  Lead.where(status: "fresh").order(created_at: :desc).limit(3).each do |lead|
    Notifier.notify([ admin, ops ], kind: "lead", title: "New lead: #{lead.company_name}", body: "#{lead.name} · #{lead.employee_count} employees", url: "/admin/leads/#{lead.id}")
  end
end

load Rails.root.join("db/seeds/operations.rb")

puts "✔ Done. #{User.count} users, #{Company.count} companies, #{Vendor.count} vendors, #{Lead.count} leads, #{Occasion.count} occasions, #{Product.count} products, #{Package.count} packages, #{Employee.count} employees, #{Booking.count} bookings."
puts "  All seeded logins use password: #{PASSWORD}"
