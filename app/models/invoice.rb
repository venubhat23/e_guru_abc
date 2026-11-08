class Invoice < ApplicationRecord
  KINDS = { "tax_invoice" => "Tax invoice", "credit_note" => "Credit note" }.freeze
  belongs_to :booking
  belongs_to :company
  belongs_to :original_invoice, class_name: "Invoice", optional: true

  validates :kind, inclusion: { in: KINDS.keys }
  validates :number, presence: true, uniqueness: true
  validates :total_paise, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { order(issued_on: :desc, id: :desc) }
  def kind_label = KINDS[kind]
  def gst_paise = cgst_paise + sgst_paise + igst_paise
  def to_param = id.to_s
end
