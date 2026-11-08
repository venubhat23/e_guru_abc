class Admin::SettingsController < Admin::BaseController
  EDITABLE = {
    "default_markup_pct" => :integer, "marketing_reserve_pct" => :integer, "price_rounding_step_rupees" => :integer,
    "assignment_sla_hours" => :integer, "auto_confirm_days" => :integer, "manual_assignment_qty_threshold" => :integer,
    "assignment_mode" => :string, "support_email" => :string, "support_phone" => :string, "lead_notification_emails" => :list
  }.freeze

  def show
    authorize Setting, :index?
    @values = EDITABLE.keys.index_with { Setting[_1] }
  end

  def update
    authorize Setting, :update?
    errors = []
    Setting.transaction do
      EDITABLE.each do |key, type|
        next unless params[:settings]&.key?(key)
        raw = params[:settings][key]
        value = case type
        when :integer then Integer(raw.to_s, exception: false)
        when :list then raw.to_s.split(/[\s,]+/).compact_blank
        else raw.to_s.strip
        end
        next errors << "#{key.humanize} must be a whole number" if value.nil?
        next errors << "Assignment mode must be auto or manual" if key == "assignment_mode" && !%w[auto manual].include?(value)
        Setting[key] = value
      end
      raise ActiveRecord::Rollback if errors.any?
    end
    errors.any? ? redirect_to(admin_settings_path, alert: errors.to_sentence) : redirect_to(admin_settings_path, notice: "Settings saved.")
  end
end
