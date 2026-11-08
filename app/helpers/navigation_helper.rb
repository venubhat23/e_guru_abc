module NavigationHelper
  def admin_nav_sections
    new_leads = Lead.where(status: "fresh").count
    counts = admin_nav_counts
    [
      { title: "Overview", items: [
        { label: "Dashboard", icon: "home", path: admin_root_path, match: %r{\A/admin/?\z} }
      ] },
      { title: "Sales", items: [
        { label: "Leads CRM", icon: "funnel", path: admin_leads_path, badge: new_leads },
        { label: "Companies", icon: "building", path: admin_companies_path }
      ] },
      { title: "Supply", items: [
        { label: "Vendors", icon: "briefcase", path: admin_vendors_path, badge: counts[:vendors_pending] },
        { label: "Catalogue", icon: "cube", path: admin_catalogue_path, match: %r{\A/admin/(catalogue|categories|products|packages|price-preview)}, badge: counts[:products_pending] },
        { label: "Offers matrix", icon: "grid", path: admin_offers_matrix_path }
      ] },
      { title: "Operations", items: [
        { label: "Bookings", icon: "clipboard", path: admin_bookings_path, badge: counts[:bookings_attention] },
        { label: "Assignments", icon: "switch", path: admin_assignments_path, badge: counts[:sla_breached] },
        { label: "Tickets", icon: "ticket", path: admin_tickets_path, badge: counts[:tickets_open] }
      ] },
      { title: "Finance", items: [
        { label: "Payments", icon: "rupee", path: admin_payments_path, badge: counts[:payments_pending] },
        { label: "Vendor payouts", icon: "banknotes", path: admin_payouts_path, badge: counts[:payouts_due] },
        { label: "Invoices", icon: "receipt", path: admin_invoices_path },
        { label: "Reports", icon: "chart", path: admin_reports_path }
      ] },
      { title: "Website", items: [
        (current_user&.super_admin? ? { label: "Traffic analytics", icon: "eye", path: admin_traffic_path } : nil),
        { label: "Occasions", icon: "sparkles", path: admin_occasions_path },
        { label: "FAQs", icon: "question", path: admin_faqs_path },
        { label: "Legal pages", icon: "scale", path: admin_legal_pages_path }
      ].compact },
      { title: "System", items: [
        { label: "Settings", icon: "settings", path: admin_settings_path },
        { label: "Audit log", icon: "clock", path: admin_audit_logs_path }
      ] }
    ]
  end

  # Sidebar badges: things that need someone's attention.
  def admin_nav_counts
    @admin_nav_counts ||= {
      vendors_pending: Vendor.where(status: "pending").count,
      products_pending: Product.pending_review.count,
      bookings_attention: Booking.where(status: "assigning").count,
      sla_breached: Assignment.sla_breached.count,
      tickets_open: Ticket.where(status: "open").count,
      payments_pending: Payment.where(status: "pending").where.not(method: "razorpay").count,
      payouts_due: VendorPayout.where(status: %w[due approved]).where(due_on: ..Date.current).count
    }
  end

  def hr_nav_sections
    [
      { title: "Workspace", items: [
        { label: "Dashboard", icon: "home", path: hr_root_path, match: %r{\A/hr/?\z} },
        { label: "Gift packages", icon: "gift", soon: true },
        { label: "Unbox builder", icon: "cube", soon: true },
        { label: "Bookings", icon: "clipboard", soon: true }
      ] },
      { title: "People", items: [
        { label: "Employees", icon: "users", soon: true },
        { label: "Team & access", icon: "shield", path: hr_team_members_path }
      ] },
      { title: "Money", items: [
        { label: "Payments", icon: "rupee", soon: true },
        { label: "Spend insights", icon: "chart", soon: true }
      ] },
      { title: "Settings", items: [
        { label: "Automations", icon: "bolt", soon: true },
        { label: "Company profile", icon: "building", path: hr_company_path }
      ] }
    ]
  end

  def vendor_nav_sections
    [
      { title: "Workspace", items: [
        { label: "Dashboard", icon: "home", path: vendor_root_path, match: %r{\A/vendor/?\z} },
        { label: "Assignments", icon: "inbox", soon: true },
        { label: "Fulfilment", icon: "truck", soon: true }
      ] },
      { title: "Catalogue", items: [
        { label: "Master catalogue", icon: "cube", soon: true },
        { label: "My offers", icon: "tag", soon: true }
      ] },
      { title: "Money", items: [
        { label: "Payouts", icon: "banknotes", soon: true },
        { label: "Earnings", icon: "trending-up", soon: true }
      ] },
      { title: "Account", items: [
        { label: "Business profile & KYC", icon: "shield", soon: true }
      ] }
    ]
  end
end
