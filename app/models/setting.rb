# Key/value platform settings with typed defaults.
class Setting < ApplicationRecord
  has_paper_trail

  DEFAULTS = {
    "default_markup_pct" => 40,
    "marketing_reserve_pct" => 20,
    "price_rounding_step_rupees" => 10,
    "assignment_sla_hours" => 24,
    "auto_confirm_days" => 3,
    "manual_assignment_qty_threshold" => 500,
    "assignment_mode" => "auto",
    "support_email" => "hello@egiftguru.in",
    "support_phone" => "+91 80 4567 8900",
    "lead_notification_emails" => [],
    "platform_legal_name" => "Avighna eGiftMitra Private Limited",
    "platform_gstin" => "29AAHCE1234F1Z9",
    "platform_state" => "Karnataka",
    "platform_address" => "91 Springboard, Koramangala 5th Block, Bengaluru 560095",
    "delivery_fee_per_recipient_rupees" => 60
  }.freeze

  validates :key, presence: true, uniqueness: true, inclusion: { in: DEFAULTS.keys }

  def self.[](key)
    key = key.to_s
    raise ArgumentError, "unknown setting #{key}" unless DEFAULTS.key?(key)
    record = find_by(key:)
    record.nil? ? DEFAULTS[key] : record.value
  end

  def self.[]=(key, value)
    find_or_initialize_by(key: key.to_s).update!(value:)
  end
end
