module ApplicationHelper
  include Pagy::Frontend

  def inr(paise, **opts) = Inr.format(paise, **opts)

  def page_title(title = nil)
    content_for(:title, title) if title
    [ content_for(:title).presence, "Avighna eGiftMitra" ].compact.join(" · ")
  end

  def meta_description(text = nil)
    content_for(:meta_description, text) if text
    content_for(:meta_description).presence ||
      "Avighna eGiftMitra is India's managed corporate gifting marketplace. Curated Diwali, New Year, birthday and onboarding gifts delivered to every employee's doorstep — GST invoices included."
  end

  LEAD_TONES = { "fresh" => :blue, "contacted" => :yellow, "demo_scheduled" => :purple, "proposal_sent" => :orange, "won" => :green, "lost" => :red }.freeze
  VENDOR_TONES = { "pending" => :yellow, "approved" => :green, "rejected" => :red, "suspended" => :gray }.freeze

  STATUS_TONES = {
    booking: { "draft" => :gray, "pending_approval" => :yellow, "awaiting_payment" => :yellow, "paid" => :blue, "assigning" => :orange,
               "assigned" => :purple, "confirmed" => :blue, "in_fulfilment" => :purple, "partially_dispatched" => :pink, "dispatched" => :pink,
               "delivered" => :green, "completed" => :green, "cancelled" => :gray, "disputed" => :red },
    assignment: { "offered" => :yellow, "accepted" => :blue, "rejected" => :red, "expired" => :gray, "in_production" => :purple,
                  "ready" => :orange, "dispatched" => :pink, "delivered" => :green },
    payment: { "pending" => :yellow, "verified" => :green, "failed" => :red, "refunded" => :gray },
    payout: { "due" => :yellow, "approved" => :blue, "paid" => :purple, "received" => :green },
    ticket: { "open" => :red, "in_progress" => :yellow, "resolved" => :green, "closed" => :gray },
    recipient: { "pending" => :gray, "in_production" => :purple, "dispatched" => :pink, "delivered" => :green },
    review: { "approved" => :green, "pending" => :yellow, "rejected" => :red }
  }.freeze
  PRIORITY_TONES = { "low" => :gray, "normal" => :blue, "high" => :orange, "urgent" => :red }.freeze

  def status_badge(kind, status, label = nil)
    render(Ui::BadgeComponent.new(text: label || status.to_s.humanize, tone: STATUS_TONES.dig(kind, status.to_s) || :gray))
  end

  def booking_badge(b) = status_badge(:booking, b.status, b.status_label)
  def pct(value) = value.nil? ? "—" : "#{value.to_f.round(1).to_s.sub(/\.0\z/, '')}%"

  def item_emoji_tile(emoji, size: "h-10 w-10 text-xl")
    tag.span(emoji, class: "grid #{size} shrink-0 place-items-center rounded-xl bg-gradient-to-br from-saffron-50 to-rani-50 ring-1 ring-saffron-100")
  end

  def lead_status_badge(lead) = render(Ui::BadgeComponent.new(text: lead.status_label, tone: LEAD_TONES[lead.status]))
  def vendor_status_badge(vendor) = render(Ui::BadgeComponent.new(text: vendor.status.humanize, tone: VENDOR_TONES[vendor.status]))
  def active_badge(active) = render(Ui::BadgeComponent.new(text: active ? "Active" : "Inactive", tone: active ? :green : :gray))

  def field_classes(record, attribute, base = "input")
    record&.errors&.include?(attribute) ? "#{base} input-error" : base
  end

  def field_error(record, attribute)
    return unless record&.errors&.include?(attribute)
    tag.p(record.errors.full_messages_for(attribute).first, class: "field-error", id: "#{attribute}_error")
  end

  def markdown(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, safe_links_only: true, with_toc_data: true)
    html = Redcarpet::Markdown.new(renderer, tables: true, autolink: true, no_intra_emphasis: true).render(text.to_s)
    sanitize(html, tags: %w[h1 h2 h3 h4 p ul ol li a strong em table thead tbody tr th td br hr blockquote code], attributes: %w[href id])
  end

  # Reads PaperTrail's stored JSON diff without loading the audited record.
  def audit_changes(version)
    raw = version.object_changes
    data = raw.is_a?(String) ? JSON.parse(raw) : raw.to_h
    data.except("updated_at", "created_at", "password_digest")
  rescue JSON::ParserError
    {}
  end

  def time_ago(time) = time ? "#{time_ago_in_words(time)} ago" : "—"

  def pagy_nav_tw(pagy)
    return "" if pagy.pages <= 1
    tag.nav(class: "mt-6 flex items-center justify-between gap-3", aria: { label: "Pagination" }) do
      info = tag.p(class: "text-sm text-slate-500") { "Showing #{pagy.from}–#{pagy.to} of #{pagy.count}" }
      links = tag.div(class: "flex items-center gap-1") do
        items = []
        items << pagy_link(pagy, pagy.prev, icon("chevron-left", class: "h-4 w-4"), "Previous")
        pagy.series.each do |item|
          items << case item
          when Integer then pagy_link(pagy, item, item.to_s)
          when String then tag.span(item, class: "grid h-9 min-w-9 place-items-center rounded-lg bg-plum-900 px-3 text-sm font-semibold text-white", aria: { current: "page" })
          else tag.span("…", class: "px-2 text-slate-400")
          end
        end
        items << pagy_link(pagy, pagy.next, icon("chevron-right", class: "h-4 w-4"), "Next")
        safe_join(items)
      end
      safe_join([ info, links ])
    end
  end

  private

  def pagy_link(pagy, page, label, aria_label = nil)
    css = "grid h-9 min-w-9 place-items-center rounded-lg px-3 text-sm font-medium ring-1 ring-slate-200 bg-white"
    return tag.span(label, class: "#{css} opacity-40") unless page
    link_to(label, pagy_url_for(pagy, page), class: "#{css} text-slate-700 hover:bg-saffron-50 hover:ring-saffron-200", aria: { label: aria_label }.compact)
  end
end
