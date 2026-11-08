# Catalogue, supply network, employees and bookings in every status — driven through the real services.
require "prawn"
Faker::Config.locale = "en-IND"
ops = User.find_by!(email_address: "ops@egiftguru.in")
finance = User.find_by!(email_address: "finance@egiftguru.in")
acme = Company.find_by!(gstin: "29AAACA1234A1Z5")
bharat = Company.find_by!(gstin: "27AABCB5678B1Z3")
acme.update!(state: "Karnataka")
bharat.update!(state: "Maharashtra")

# ---------- Categories ----------
cats = {
  "chocolates" => [ "Chocolates", "🍫", true, nil ], "cups-mugs" => [ "Cups & Mugs", "☕", false, nil ], "earphones" => [ "Earphones", "🎧", false, 30 ],
  "bags" => [ "Bags", "👜", false, nil ], "greeting-cards" => [ "Greeting Cards", "💌", false, 60 ], "organic-sweets" => [ "Organic Sweets", "🍬", true, nil ],
  "paintings" => [ "Paintings", "🖼️", false, 50 ], "diaries" => [ "Diaries", "📔", false, nil ], "bottles" => [ "Bottles", "🧴", false, nil ],
  "t-shirts" => [ "T-shirts", "👕", false, nil ], "dry-fruits" => [ "Dry Fruits", "🥜", true, 35 ], "decor" => [ "Diyas & Decor", "🪔", false, nil ]
}.each_with_index.to_h do |(slug, (name, emoji, food, markup)), i|
  [ slug, Category.find_or_initialize_by(slug:).tap { _1.update!(name:, emoji:, food:, markup_override_pct: markup, position: i) } ]
end

# ---------- Products ----------
products = [
  [ "CHO-001", "chocolates", "Belgian Dark Chocolate Box (12 pc)", "1806", 18, 2, false, "🍫" ],
  [ "CHO-002", "chocolates", "Artisan Truffle Collection", "1806", 18, 2, true, "🍫" ],
  [ "MUG-001", "cups-mugs", "Ceramic Magic Mug", "6912", 12, 2, true, "☕" ],
  [ "MUG-002", "cups-mugs", "Insulated Travel Tumbler", "7323", 18, 2, true, "🥤" ],
  [ "EAR-001", "earphones", "Wireless Earbuds Pro", "8518", 18, 1, true, "🎧" ],
  [ "BAG-001", "bags", "Laptop Backpack 15.6\"", "4202", 18, 4, true, "🎒" ],
  [ "BAG-002", "bags", "Jute Tote Bag", "4202", 18, 2, true, "👜" ],
  [ "CRD-001", "greeting-cards", "Personalised Greeting Card", "4909", 12, 1, true, "💌" ],
  [ "CRD-002", "greeting-cards", "Welcome Card from Leadership", "4909", 12, 1, true, "✉️" ],
  [ "SWT-001", "organic-sweets", "Organic Kaju Katli (500 g)", "1704", 5, 2, false, "🍬" ],
  [ "SWT-002", "organic-sweets", "Assorted Ghee Laddoos (500 g)", "1704", 5, 2, false, "🟠" ],
  [ "PNT-001", "paintings", "Madhubani Art Print (A4, framed)", "9701", 12, 3, false, "🖼️" ],
  [ "DIA-001", "diaries", "Premium Vegan Leather Diary 2027", "4820", 18, 1, true, "📔" ],
  [ "BOT-001", "bottles", "Steel Water Bottle 750 ml", "7323", 18, 2, true, "🧴" ],
  [ "TSH-001", "t-shirts", "Cotton Crew T-shirt", "6109", 5, 1, true, "👕", { "sizes" => Employee::TSHIRT_SIZES, "colours" => %w[White Navy Black] } ],
  [ "DRY-001", "dry-fruits", "Premium Dry Fruit Box (400 g)", "0813", 12, 3, false, "🥜" ],
  [ "DEC-001", "decor", "Hand-painted Terracotta Diyas (set of 4)", "6913", 12, 2, false, "🪔" ],
  [ "DEC-002", "decor", "Brass Urli with Floating Candles", "7418", 12, 3, false, "🏺" ]
].to_h do |sku, cat, name, hsn, gst, vol, brandable, emoji, variants|
  [ sku, Product.find_or_initialize_by(sku:).tap do |p|
    p.update!(category: cats[cat], name:, hsn_code: hsn, gst_rate: gst, volume_units: vol, brandable:, emoji:, variants: variants || {},
              description: "#{name}. Carefully sourced and quality-checked, suitable for corporate gifting.")
  end ]
end
tech = Vendor.find_by!(business_name: "TechTreats Gadgets")
Product.find_or_initialize_by(sku: "EAR-002").update!(category: cats["earphones"], name: "Bluetooth Neckband Earphones", hsn_code: "8518", gst_rate: 18,
  volume_units: 1, brandable: true, emoji: "🎧", review_status: "pending", proposed_by_vendor: tech, description: "Proposed by TechTreats: 20h battery, IPX5.")

# ---------- Packages ----------
occ = Occasion.all.index_by(&:slug)
packages = {
  "onboarding-kit" => [ "Onboarding Kit", "onboarding", 10, "🎒", { "TSH-001" => 1, "BOT-001" => 1, "DIA-001" => 1, "CRD-002" => 1 }, "Branded T-shirt, steel bottle, diary and a welcome card from leadership." ],
  "onboarding-pro" => [ "Onboarding Pro Kit", "onboarding", 10, "💼", { "TSH-001" => 1, "BAG-001" => 1, "BOT-001" => 1, "DIA-001" => 1, "CRD-002" => 1 }, "Everything in the Onboarding Kit plus a laptop backpack." ],
  "diwali-delight" => [ "Diwali Delight Hamper", "diwali", 10, "🪔", { "DRY-001" => 1, "SWT-001" => 1, "DEC-001" => 1, "CRD-001" => 1 }, "Dry fruits, organic kaju katli, terracotta diyas and a personalised card." ],
  "diwali-premium" => [ "Diwali Premium Hamper", "diwali", 10, "✨", { "DRY-001" => 1, "CHO-002" => 1, "DEC-002" => 1, "PNT-001" => 1, "CRD-001" => 1 }, "A luxurious hamper with truffles, brass urli and Madhubani art." ],
  "new-year-productivity" => [ "New Year Productivity Kit", "new-year", 10, "🎆", { "DIA-001" => 1, "MUG-002" => 1, "EAR-001" => 1, "CRD-001" => 1 }, "Start the year right: diary, tumbler and wireless earbuds." ],
  "birthday-treat" => [ "Birthday Treat Box", "birthday", 5, "🎂", { "CHO-001" => 1, "MUG-001" => 1, "CRD-001" => 1 }, "Chocolates, a personalised magic mug and a birthday card." ],
  "festival-sweets" => [ "Festival Sweets Box", "festival", 10, "🍬", { "SWT-002" => 1, "SWT-001" => 1, "BAG-002" => 1, "CRD-001" => 1 }, "Two organic mithai boxes in a jute tote with a festive card." ]
}.to_h do |slug, (name, occasion, min_qty, emoji, items, description)|
  pkg = Package.find_or_initialize_by(slug:)
  if pkg.new_record?
    pkg.assign_attributes(name:, occasion: occ.fetch(occasion), min_qty:, emoji:, description:)
    items.each { |sku, qty| pkg.package_items.build(product: products.fetch(sku), quantity: qty) }
    pkg.save!
  end
  [ slug, pkg ]
end

# ---------- Vendors: KYC, bank, regions, offers ----------
def kyc_pdf(title, vendor)
  Prawn::Document.new do |pdf|
    pdf.text title, size: 20, style: :bold
    pdf.move_down 10
    pdf.text "Issued to: #{vendor.business_name}"
    pdf.text "GSTIN: #{vendor.gstin}" if vendor.gstin
    pdf.text "Sample document generated for the Avighna eGiftMitra demo."
  end.render
end

network = {
  "SweetCraft Foods" => { contact: "Meera Agarwal", pan: "AABCS1111K", fssai: "12219876543210", city: "Jaipur", state: "Rajasthan", pin: "302001", rating: 4.7,
                          regions: [ [ "Rajasthan" ], [ "Karnataka" ], [ "Maharashtra" ], [ "Delhi" ], [ "Tamil Nadu" ] ],
                          offers: { "diwali-delight" => [ 1050, 20, 400, 7, 30, "on_delivery", 0 ], "diwali-premium" => [ 1900, 10, 150, 9, 30, "on_delivery", 0 ], "festival-sweets" => [ 620, 20, 500, 5, 25, "credit", 15 ], "birthday-treat" => [ 540, 5, 300, 6, 0, "on_delivery", 0 ] } },
  "PrintPerfect Merch" => { contact: "Sanjay Gupta", pan: "AACCP2222L", city: "New Delhi", state: "Delhi", pin: "110020", rating: 4.4,
                            regions: [ [ "Delhi" ], [ "Haryana" ], [ "Uttar Pradesh" ], [ "Maharashtra" ], [ "Karnataka", "Bengaluru" ] ],
                            offers: { "onboarding-kit" => [ 890, 10, 300, 8, 40, "on_delivery", 0 ], "onboarding-pro" => [ 1950, 10, 120, 10, 40, "credit", 30 ], "new-year-productivity" => [ 1650, 10, 200, 9, 30, "on_delivery", 0 ], "birthday-treat" => [ 560, 5, 200, 6, 20, "on_delivery", 0 ] } },
  "Kala Handicrafts" => { contact: "Lakshmi Menon", pan: "AADCK3333M", city: "Kochi", state: "Kerala", pin: "682016", rating: 4.8,
                          regions: [ [ "Kerala" ], [ "Tamil Nadu" ], [ "Karnataka" ] ],
                          offers: { "diwali-delight" => [ 1120, 10, 200, 6, 50, "on_delivery", 0 ], "diwali-premium" => [ 1820, 10, 80, 8, 50, "on_delivery", 0 ], "festival-sweets" => [ 650, 10, 150, 6, 20, "on_delivery", 0 ] } },
  "TechTreats Gadgets" => { contact: "Imran Shaikh", pan: "AAECT4444N", city: "Mumbai", state: "Maharashtra", pin: "400072", rating: 4.2,
                            regions: [ [ "Maharashtra" ], [ "Gujarat" ], [ "Karnataka" ], [ "Telangana" ], [ "Delhi" ] ],
                            offers: { "new-year-productivity" => [ 1580, 10, 250, 7, 25, "credit", 30 ], "onboarding-kit" => [ 940, 10, 200, 7, 30, "on_delivery", 0 ], "onboarding-pro" => [ 2010, 10, 100, 8, 30, "on_delivery", 0 ] } },
  "GreenLeaf Organics" => { contact: "Ritu Bansal", pan: nil, city: "Dehradun", state: "Uttarakhand", pin: "248001", rating: 4.0,
                            regions: [ [ "Uttarakhand" ], [ "Delhi" ] ], offers: { "festival-sweets" => [ 580, 10, 300, 6, 20, "on_delivery", 0 ] } }
}
network.each do |name, cfg|
  v = Vendor.find_by!(business_name: name)
  v.update!(contact_name: cfg[:contact], legal_name: "#{name} Private Limited", pan: cfg[:pan] || v.pan, fssai_number: cfg[:fssai],
            warehouse_address: "Plot #{rand(10..99)}, Industrial Area", warehouse_city: cfg[:city], warehouse_state: cfg[:state], warehouse_pincode: cfg[:pin],
            bank_account_name: "#{name} Pvt Ltd", bank_account_number: v.gstin ? "5010#{rand(10**9..10**10 - 1)}" : nil, bank_ifsc: v.gstin ? "HDFC0001234" : nil,
            rating: cfg[:rating], approved_at: v.approved? ? 60.days.ago : nil)
  if v.regions.none?
    cfg[:regions].each { |state, city| v.regions.create!(state:, city:) }
  end
  cfg[:offers].each do |slug, (price, moq, cap, lead, adv, terms, credit)|
    v.offers.find_or_initialize_by(offerable: packages.fetch(slug)).update!(vendor_price_paise: price * 100, moq:, capacity_per_week: cap, lead_time_days: lead,
                                                                           advance_pct: adv, balance_terms: terms, credit_days: credit, active: true)
  end
  # product-level offers for the catalogue / Unbox pricing
  products.values.sample(6, random: Random.new(v.id)).each do |prod|
    v.offers.find_or_initialize_by(offerable: prod).update!(vendor_price_paise: rand(120..900) * 100, moq: 10, capacity_per_week: 500, lead_time_days: rand(4..9), advance_pct: 20)
  end
  unless v.kyc_documents.attached? || v.gstin.blank?
    v.kyc_documents.attach(io: StringIO.new(kyc_pdf("GST Registration Certificate", v)), filename: "gst-certificate.pdf", content_type: "application/pdf")
    v.kyc_documents.attach(io: StringIO.new(kyc_pdf("PAN Card", v)), filename: "pan-card.pdf", content_type: "application/pdf")
    v.kyc_documents.attach(io: StringIO.new(kyc_pdf("FSSAI Licence", v)), filename: "fssai-licence.pdf", content_type: "application/pdf") if v.fssai_number
  end
end

# ---------- Employees (50 per company) ----------
cities = {
  acme => [ [ "Bengaluru", "Karnataka", 560001..560103, 34 ], [ "Mumbai", "Maharashtra", 400001..400104, 8 ], [ "Chennai", "Tamil Nadu", 600001..600119, 8 ] ],
  bharat => [ [ "Mumbai", "Maharashtra", 400001..400104, 26 ], [ "Pune", "Maharashtra", 411001..411062, 10 ], [ "New Delhi", "Delhi", 110001..110096, 14 ] ]
}
depts = %w[Engineering Sales Marketing Finance HR Operations Design Support]
cities.each do |company, groups|
  next if company.employees.count >= 50
  n = 0
  groups.each do |city, state, pins, count|
    count.times do
      n += 1
      first, last = Faker::Name.first_name, Faker::Name.last_name
      company.employees.create!(emp_code: "#{company.name.first(3).upcase}#{n.to_s.rjust(4, '0')}", name: "#{first} #{last}",
        email: "#{first}.#{last}@#{company.name.parameterize}.example".downcase.delete("'"), phone: "+91 9#{rand(100_000_000..999_999_999)}",
        department: depts.sample, designation: %w[Associate Senior\ Associate Manager Lead Director].sample, location: city,
        address: "#{rand(1..300)}, #{Faker::Address.street_name}, #{Faker::Address.community}", city:, state:, pincode: rand(pins).to_s,
        dob: Faker::Date.birthday(min_age: 22, max_age: 55), joining_date: Faker::Date.between(from: 5.years.ago, to: 1.month.ago),
        tshirt_size: Employee::TSHIRT_SIZES.sample)
    end
  end
  # two future joiners for onboarding automations later
  2.times { |i| company.employees.create!(emp_code: "#{company.name.first(3).upcase}J#{i + 1}", name: Faker::Name.name, city: groups.first[0], state: groups.first[1], pincode: rand(groups.first[2]).to_s, joining_date: (15 + i * 7).days.from_now, tshirt_size: "M", address: "Address to be confirmed") }
end

# ---------- Bookings in every status ----------
if Booking.none?
  hr_acme = User.find_by!(email_address: "hr@acmetech.in")
  hr_bharat = User.find_by!(email_address: "hr@bharatretail.in")
  workflow = Assignment::Workflow
  date = ->(days) { Date.current + days }

  make = lambda do |company, user, pkg, employees, days, **opts|
    Bookings::Creator.call(company:, user:, bookable: packages.fetch(pkg), employees:, requested_delivery_on: date.(days),
                           personalisation: { "card_message" => "Dear {name}, thank you for everything you do! — Team #{company.name}", "logo" => true }, **opts)
  end
  pay_online = lambda do |b|
    p = b.payments.create!(method: "razorpay", amount_paise: b.total_paise, razorpay_order_id: "order_seed_#{b.id}", razorpay_payment_id: "pay_seed_#{b.id}",
                           gateway_fee_paise: (b.total_paise * 0.02).round)
    Payments::Recorder.verify!(p, by: finance)
  end
  run_to = lambda do |b, stage|
    raise "#{b.number}: expected an assigned booking, got #{b.reload.status} (no eligible vendor?)" unless b.assigned?
    a = b.reload.live_assignments.to_a
    a.each { workflow.accept!(_1) } if %i[confirmed production dispatched delivered completed].include?(stage)
    a.each { workflow.start_production!(_1.reload) } if %i[production dispatched delivered completed].include?(stage)
    a.each do |x|
      next unless %i[dispatched delivered completed].include?(stage)
      workflow.mark_ready!(x.reload)
      workflow.dispatch!(x.reload, tracking: x.recipients.to_h { |r| [ r.id, { courier: %w[Delhivery Blue\ Dart DTDC].sample, awb: "AWB#{rand(10**9..10**10 - 1)}" } ] })
    end
    a.each { workflow.deliver!(_1.reload) } if %i[delivered completed].include?(stage)
    b.reload.mark_delivered! if %i[delivered completed].include?(stage)
    if stage == :completed
      b.reload.payouts.each do |po|
        Payouts::Workflow.approve!(po, by: finance)
        Payouts::Workflow.pay!(po, utr: "UTR#{rand(10**11..10**12 - 1)}")
        Payouts::Workflow.receive!(po.reload)
      end
    end
    b.reload
  end

  acme_blr = acme.employees.where(state: "Karnataka").order(:id).to_a
  acme_all = acme.employees.where.not(address: "Address to be confirmed").order(:id).to_a
  bh_mh = bharat.employees.where(state: "Maharashtra").order(:id).to_a
  bh_all = bharat.employees.where.not(address: "Address to be confirmed").order(:id).to_a

  # 1. Draft
  make.(acme, hr_acme, "birthday-treat", acme_blr.first(6), 12)
  # 2. Pending approval (above Acme's ₹1,00,000 limit)
  make.(acme, hr_acme, "diwali-premium", acme_all.first(45), 20).tap(&:submit!)
  # 3. Awaiting payment + an offline bank transfer waiting for finance to verify
  b = make.(acme, hr_acme, "onboarding-kit", acme_blr.first(12), 18).tap(&:submit!)
  Payments::Recorder.record_offline!(booking: b, method: "bank_transfer", amount_paise: b.total_paise, reference: "NEFT/HDFC/#{rand(10**8..10**9)}",
                                     proof: { io: StringIO.new(kyc_pdf("NEFT Payment Advice", Vendor.first)), filename: "neft-advice.pdf", content_type: "application/pdf" })
  # 4. Paid (assignment not started yet)
  b = make.(acme, hr_acme, "birthday-treat", acme_blr.last(8), 16).tap(&:submit!)
  b.payments.create!(method: "razorpay", amount_paise: b.total_paise, razorpay_order_id: "order_seed_#{b.id}", gateway_fee_paise: (b.total_paise * 0.02).round).tap { _1.verify! }
  b.mark_paid!
  # 5. Assigning — manual queue (Bharat is on credit terms → straight to assigning)
  bharat.update!(assignment_mode_override: "manual")
  b = make.(bharat, hr_bharat, "onboarding-pro", bh_all.first(20), 21).tap(&:submit!)
  Assignment::Router.call(b)
  bharat.update!(assignment_mode_override: nil)
  # 6. Assigned (auto, offered to vendor, SLA running)
  b = make.(acme, hr_acme, "diwali-delight", acme_blr.first(25), 15).tap(&:submit!)
  pay_online.(b)
  # 6b. Assigned with SLA already breached (shows in overdue SLAs)
  b = make.(bharat, hr_bharat, "festival-sweets", bh_mh.first(20), 14).tap(&:submit!)
  Assignment::Router.call(b)
  b.reload.live_assignments.update_all(expires_at: 3.hours.ago)
  # 7. Confirmed
  b = make.(acme, hr_acme, "new-year-productivity", acme_blr.last(20), 25).tap(&:submit!)
  pay_online.(b); run_to.(b, :confirmed)
  # 8. In fulfilment
  b = make.(bharat, hr_bharat, "new-year-productivity", bh_mh.first(18), 20).tap(&:submit!)
  Assignment::Router.call(b); run_to.(b, :production)
  # 9. Partially dispatched — split across two vendors by region (Maharashtra → TechTreats, Delhi → PrintPerfect)
  b = make.(bharat, hr_bharat, "onboarding-kit", bh_all.first(10) + bharat.employees.where(state: "Delhi").limit(10).to_a, 18).tap(&:submit!)
  b.update_column(:assignment_mode, "manual")
  Assignment::Manual.call(booking: b, offer: tech.offers.find_by!(offerable: packages["onboarding-kit"]), state: "Maharashtra")
  Assignment::Manual.call(booking: b, offer: Vendor.find_by!(business_name: "PrintPerfect Merch").offers.find_by!(offerable: packages["onboarding-kit"]), state: "Delhi")
  run_to.(b, :production)
  first = b.reload.live_assignments.first
  workflow.mark_ready!(first)
  workflow.dispatch!(first.reload, tracking: first.recipients.to_h { |r| [ r.id, { courier: "Delhivery", awb: "AWB#{rand(10**9..10**10 - 1)}" } ] })
  # 10. Dispatched
  b = make.(acme, hr_acme, "festival-sweets", acme_all.last(20), 14).tap(&:submit!)
  pay_online.(b); run_to.(b, :dispatched)
  b.reload.recipients.limit(5).update_all(status: "delivered", delivered_at: 1.day.ago)
  # 11. Delivered (awaiting vendor payouts)
  b = make.(acme, hr_acme, "onboarding-kit", acme_blr.first(15), 16).tap(&:submit!)
  pay_online.(b); run_to.(b, :delivered)
  # 12. Disputed (with a ticket) — blocks the vendor balance payout
  b = make.(bharat, hr_bharat, "diwali-delight", bh_mh.last(20), 15).tap(&:submit!)
  Assignment::Router.call(b); run_to.(b, :delivered)
  r = b.recipients.first
  b.tickets.create!(company: bharat, raised_by: hr_bharat, booking_recipient: r, category: "damaged", priority: "high",
                    subject: "Diyas broken on arrival for #{r.name}", description: "Two of the four diyas were cracked. Photos attached in email.")
  b.reload.update!(dispute_reason: "Damaged items reported by HR")
  b.dispute!
  # 13. Cancelled after payment → refund + credit note
  b = make.(acme, hr_acme, "birthday-treat", acme_blr.first(10), 15).tap(&:submit!)
  pay_online.(b)
  Bookings::Canceller.call(booking: b.reload, reason: "Event postponed by client", actor: ops)
  # 14. Completed bookings spread over past months (for dashboard & reports)
  [ [ acme, hr_acme, "diwali-delight", acme_blr.first(30), 5 ], [ acme, hr_acme, "onboarding-kit", acme_blr.last(14), 4 ], [ bharat, hr_bharat, "festival-sweets", bh_mh.first(25), 3 ],
   [ bharat, hr_bharat, "new-year-productivity", bh_mh.last(16), 2 ], [ acme, hr_acme, "diwali-premium", acme_all.first(20), 1 ], [ bharat, hr_bharat, "onboarding-pro", bh_all.last(12), 0 ] ].each do |company, user, pkg, emps, months_ago|
    b = make.(company, user, pkg, emps, 20).tap(&:submit!)
    company.credit? ? Assignment::Router.call(b) : pay_online.(b)
    run_to.(b, :completed)
    t = months_ago.months.ago - rand(0..10).days
    b.update_columns(created_at: t - 20.days, submitted_at: t - 20.days, paid_at: t - 19.days, confirmed_at: t - 18.days, delivered_at: t, completed_at: t + 2.days, requested_delivery_on: (t + 1.day).to_date)
    b.ledger_entries.update_all(posted_at: t + 2.days, created_at: t + 2.days)
    b.invoices.update_all(issued_on: (t + 2.days).to_date, created_at: t + 2.days)
    b.assignments.update_all(delivered_at: t, created_at: t - 18.days)
    b.recipients.update_all(delivered_at: t, dispatched_at: t - 2.days)
    VendorPayout.where(assignment_id: b.assignments.select(:id)).find_each do |po|
      d = po.kind == "advance" ? t - 18.days : t
      po.update_columns(due_on: d.to_date, approved_at: d + 1.day, paid_at: d + 2.days, received_at: d + 3.days, created_at: d)
    end
  end
  # Payouts in every state: approve one advance, approve + pay another
  confirmed_adv = Booking.find_by(status: "confirmed").payouts.find_by(kind: "advance")
  Payouts::Workflow.approve!(confirmed_adv, by: finance) if confirmed_adv
  Booking.where(status: %w[in_fulfilment partially_dispatched]).flat_map { _1.payouts.where(kind: "advance").to_a }.each do |po|
    Payouts::Workflow.approve!(po, by: finance)
    Payouts::Workflow.pay!(po, utr: "UTR#{rand(10**11..10**12 - 1)}")
  end
  # A ticket on a dispatched booking and a resolved one
  dispatched = Booking.find_by(status: "dispatched")
  dispatched.tickets.create!(company: dispatched.company, raised_by: hr_acme, booking_recipient: dispatched.recipients.last, category: "not_delivered",
                             subject: "Courier shows delivered but employee hasn't received", assignee: ops).tap(&:start!)
  done = Booking.where(status: "completed").first
  t = done.tickets.create!(company: done.company, raised_by: hr_acme, category: "wrong_item", priority: "low", subject: "Wrong T-shirt size for one employee", assignee: ops)
  t.comments.create!(user: ops, body: "Replacement dispatched via Blue Dart.")
  t.update!(resolution: "Replacement T-shirt delivered.")
  t.resolve!
end
