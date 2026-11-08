require "csv"
# Tabular reports with CSV export. Money columns are integer paise; `money` lists which columns to format.
module Reports
  class Builder
    REPORTS = {
      "gmv_by_month" => "GMV & margin by month", "gmv_by_occasion" => "GMV & margin by occasion", "gmv_by_company" => "GMV & margin by company",
      "gmv_by_vendor" => "Fulfilment value by vendor", "vendor_performance" => "Vendor performance", "lead_conversion" => "Lead conversion"
    }.freeze
    Report = Struct.new(:key, :title, :columns, :rows, :money, keyword_init: true) do
      def to_csv
        CSV.generate do |csv|
          csv << columns
          rows.each { |r| csv << r.each_with_index.map { |v, i| money.include?(i) ? (v.to_i / 100.0) : v } }
        end
      end
    end

    def initialize(key, from: 12.months.ago.beginning_of_month, to: Time.current)
      raise ArgumentError, "unknown report" unless REPORTS.key?(key)
      @key, @range = key, from..to
    end

    def call = Report.new(key: @key, title: REPORTS[@key], **send(@key))

    private

    def bookings = Booking.committed.where(created_at: @range)

    def margin_rows(grouped)
      grouped.map do |label, (count, kits, gmv, vendor)|
        margin = vendor.to_i.positive? ? gmv - vendor : 0
        [ label, count, kits, gmv, vendor, margin, gmv.to_i.zero? || vendor.to_i.zero? ? "—" : "#{(margin * 100.0 / gmv).round(1)}%" ]
      end
    end

    MARGIN_COLS = [ "Bookings", "Kits", "GMV (excl. GST)", "Vendor cost", "Gross margin", "Margin %" ].freeze
    AGG = "COUNT(*), SUM(bookings.quantity), SUM(bookings.hr_subtotal_paise), SUM(bookings.vendor_subtotal_paise)".freeze

    def gmv_by_month
      rows = bookings.group(Arel.sql("date_trunc('month', bookings.created_at)")).order(Arel.sql("1")).pluck(Arel.sql("date_trunc('month', bookings.created_at)"), Arel.sql(AGG))
      { columns: [ "Month", *MARGIN_COLS ], rows: margin_rows(rows.map { |m, *v| [ m.strftime("%b %Y"), v ] }), money: [ 3, 4, 5 ] }
    end

    def gmv_by_occasion
      rows = bookings.left_joins(:occasion).group("occasions.name").pluck(Arel.sql("COALESCE(occasions.name, 'Other')"), Arel.sql(AGG))
      { columns: [ "Occasion", *MARGIN_COLS ], rows: margin_rows(rows.map { |n, *v| [ n, v ] }.sort_by { -_2[2].to_i }), money: [ 3, 4, 5 ] }
    end

    def gmv_by_company
      rows = bookings.joins(:company).group("companies.id").pluck(Arel.sql("COALESCE(companies.display_name, companies.legal_name)"), Arel.sql(AGG))
      { columns: [ "Company", *MARGIN_COLS ], rows: margin_rows(rows.map { |n, *v| [ n, v ] }.sort_by { -_2[2].to_i }), money: [ 3, 4, 5 ] }
    end

    def gmv_by_vendor
      rows = Assignment.live.joins(:vendor, :booking).where(bookings: { created_at: @range }).group("vendors.id")
                       .pluck(Arel.sql("vendors.business_name, COUNT(DISTINCT assignments.booking_id), SUM(assignments.quantity), SUM(assignments.quantity * bookings.unit_price_paise), SUM(assignments.vendor_total_paise)"))
      { columns: [ "Vendor", *MARGIN_COLS ], rows: margin_rows(rows.map { |n, *v| [ n, v ] }.sort_by { -_2[2].to_i }), money: [ 3, 4, 5 ] }
    end

    def vendor_performance
      rows = Vendor.order(:business_name).map do |v|
        p = v.performance
        paid = v.payouts.where(status: %w[paid received]).sum(:amount_paise)
        [ v.business_name, v.status.humanize, v.rating.to_f, p[:total], p[:delivered], "#{p[:rejection_pct]}%", p[:on_time_pct] ? "#{p[:on_time_pct]}%" : "—", paid ]
      end
      { columns: [ "Vendor", "Status", "Rating", "Assignments", "Delivered", "Rejected/expired", "On-time", "Paid out" ], rows:, money: [ 7 ] }
    end

    def lead_conversion
      rows = Lead.where(created_at: @range).group(Arel.sql("date_trunc('month', created_at)")).order(Arel.sql("1"))
                 .pluck(Arel.sql("date_trunc('month', created_at), COUNT(*), COUNT(*) FILTER (WHERE status = 'won'), COUNT(*) FILTER (WHERE status = 'lost'), COUNT(*) FILTER (WHERE status NOT IN ('won','lost'))"))
      { columns: [ "Month", "Leads", "Won", "Lost", "Open", "Win rate (closed)" ], money: [],
        rows: rows.map { |m, total, won, lost, open| [ m.strftime("%b %Y"), total, won, lost, open, (won + lost).zero? ? "—" : "#{(won * 100.0 / (won + lost)).round}%" ] } }
    end
  end
end
