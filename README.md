# Avighna eGiftMitra

Managed corporate-gifting marketplace for India. Rails 8.1 · Ruby 3.3 · PostgreSQL · Hotwire · Tailwind v4 · ViewComponent · Pundit · AASM · PaperTrail · Solid Queue.

Four portals, each with its own layout and sidebar:

| Portal | Path | Roles |
|---|---|---|
| Public website | `/` | anyone |
| Platform admin | `/admin` | super_admin, ops_admin, finance_admin |
| HR workspace | `/hr` | hr_admin, hr_member (scoped to their Company) |
| Vendor partner | `/vendor` | vendor_owner, vendor_staff (scoped to their Vendor) |

## Run locally

```bash
cp .env.example .env          # optional: set DATABASE_URL or DB_* (defaults to local Postgres socket)
bundle install
bin/rails db:prepare db:seed
bin/dev                       # web + Tailwind watcher on http://localhost:3000
bundle exec rspec             # test suite
```

Emails in development open at **http://localhost:3000/letter_opener**.

## Sample logins (password `Password@123`)

| Role | Email |
|---|---|
| Super admin | admin@egiftguru.in |
| Ops admin | ops@egiftguru.in |
| Finance admin | finance@egiftguru.in |
| HR admin — Acme Technologies | hr@acmetech.in |
| HR member — Acme Technologies | people@acmetech.in |
| HR admin — Bharat Retail | hr@bharatretail.in |
| Vendor (approved) | vendor@sweetcraft.in |
| Vendor (pending) | vendor@greenleaf.in |

Override the seed password with `SEED_PASSWORD=... bin/rails db:seed`.

## Managing website content (no code needed)

Sign in as an admin → sidebar **Website**:

- **Legal pages**: Terms of Service, Privacy Policy (DPDP Act 2023), Refund & Cancellation, Shipping & Delivery, Vendor Terms. Written in Markdown with a live preview; publish/unpublish; every edit is in the **Audit log**. Published pages appear in the footer automatically.
- **FAQs**: public FAQs show on the homepage, vendor FAQs on `/become-a-vendor`. Set order and active flag.
- **Occasions**: homepage cards and `/gifts/:slug` pages (emoji, colour theme, tagline, highlights, "from ₹X per employee", season dates).

**System → Settings** holds platform defaults (markup 40%, marketing reserve 20%, round to ₹10, SLA 24h, auto-confirm 3 days, manual review above 500 kits, assignment mode, support contacts). Only super admins can change them.

## Deploy to Railway

1. Create a service from this repo; Railway uses `railway.json` + `Dockerfile`.
2. Add a Postgres plugin and set these service variables:
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}` (the private `postgres.railway.internal` URL)
   - `RAILS_MASTER_KEY` = contents of `config/master.key` (never commit it)
   - `APP_HOST` = your domain, `SOLID_QUEUE_IN_PUMA=1`
   - `SEED_ON_DEPLOY=true` for the first deploy (seeds are idempotent; set back to `false` afterwards)
3. Deploy. The entrypoint runs `db:prepare` (and `db:seed` if enabled), and maps Railway's `$PORT` to Thruster.

Production uses **one database**: Solid Queue/Cache/Cable tables live in the primary DB (`db/migrate/*_create_solid_tables.rb`). Kamal config (`config/deploy.yml`) is also present and will be finalised in Phase 7.

## Admin: supply, operations & finance

| Area | Path | What it does |
|---|---|---|
| Vendors | `/admin/vendors` | Approval queue, KYC viewer (GSTIN/PAN/FSSAI/bank, encrypted account no.), approve / reject (reason) / suspend (pauses offers), regions, offers, performance (rating, on-time %, rejection %) |
| Catalogue | `/admin/catalogue` | Categories (markup overrides, food flag), products (HSN, GST, volume, variants), packages with nested items, vendor-proposed product review |
| Price preview | `/admin/price-preview` | Shows markup source (company › product › category › default) and rounding for any item/company |
| Offers matrix | `/admin/offers-matrix` | Every vendor offer for an item: price, MOQ, capacity left this week, lead time, regions, terms, rating, margin |
| Bookings | `/admin/bookings` | Inbox with filters; booking page with timeline, HR + vendor price breakdown, manual assignment comparison panel (split by state or quantity), recipients & tracking, payments, documents, tickets, status history; cancel (refund + credit note), dispute, confirm delivery |
| Assignments | `/admin/assignments` | All vendor jobs with SLA countdown; expire to release capacity and reassign; packing list & label PDFs |
| Tickets | `/admin/tickets` | Triage, assign, comment (internal notes), resolve with resolution |
| Payments | `/admin/payments` | Razorpay (signed, idempotent webhook at `POST /webhooks/razorpay`) and offline proof verification (finance only) |
| Vendor payouts | `/admin/payouts` | Advance on acceptance, balance on delivery/credit days; finance approves (with penalty) → records UTR → vendor confirms receipt; blocked while disputed |
| Invoices | `/admin/invoices` | GST tax invoices `INV/2026-27/0001` and credit notes `CN/…`, numbered per financial year; PDF download |
| Reports | `/admin/reports` | GMV & margin by month / occasion / company / vendor, vendor performance, lead conversion — all CSV-exportable |

Core services: `Pricing::Calculator`, `Gst::Splitter` (CGST+SGST vs IGST by place of supply), `Bookings::Creator/Quote/Canceller/Completer`,
`Assignment::Router/AutoAssigner/Eligibility/CapacityChecker/Creator/Manual/Workflow`, `Payouts::Scheduler/Workflow`, `Payments::Recorder/RazorpayWebhook`,
`Invoices::Issuer`, `Ledger::Poster` (revenue, marketing reserve, gateway fees — posted in the same transaction as completion).
Recurring jobs (`config/recurring.yml`): `AssignmentSlaJob` every 15 min, `AutoConfirmDeliveriesJob` hourly.

Seeds create 12 categories, 19 products, 7 packages, 5 vendors with regions/offers/KYC documents, 50+ employees per company and bookings in **every** status.

## Architecture notes

- **Money** is always integer paise (`*_paise` bigint). Use `Inr.format(paise)`, which renders ₹1,00,000 grouping.
- **Tenancy**: `Hr::BaseController` sets `Current.company` and `Vendor::BaseController` sets `Current.vendor`. Pundit policy scopes filter every query, and `verify_authorized` / `verify_policy_scoped` are enforced on all portal actions.
- **Leads**: `Leads::Intake` (create + auto-reply + admin email + bell notification) and `Leads::Converter` (Company creation + mark won, in one transaction).
- **Abuse protection**: honeypot fields on public forms, Rack::Attack throttles (contact 5/10 min per IP, vendor signup, login), and Rails `rate_limit` on auth.
- AASM event `after` callbacks run **after** save — set attributes in `before` (see `VendorPayout`).
- `json` is pinned `< 3` because json 3.x broke ActiveSupport 8.0 JSON encoding (`quirks_mode`). Re-test before lifting it.

## Phase status

- [x] **Phase 1**: setup, auth (email verification, password reset), roles, tenancy, four layouts, public site, Contact Us → leads, admin leads CRM, website CMS, settings, audit log
- [x] Admin supply/operations/finance: vendors, catalogue, offers matrix, bookings, assignments, tickets, payments, payouts, invoices, reports, live dashboard
- [ ] Phase 2 (remaining): vendor-portal onboarding wizard & offer management UI
- [ ] Phase 3: pricing engine, HR company setup, employees + import
- [ ] Phase 4: packages, Unbox builder, booking wizard, proforma
- [ ] Phase 5: payments, assignment, SLA
- [ ] Phase 6: fulfilment, payouts, invoices, ledgers, reports
- [ ] Phase 7: automations, tickets, hardening, Kamal
