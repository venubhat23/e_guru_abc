class VendorSignup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :business_name, :string
  attribute :name, :string
  attribute :email_address, :string
  attribute :phone, :string
  attribute :password, :string
  attribute :city, :string
  attribute :terms, :boolean

  attr_reader :vendor, :user

  validates :business_name, :name, :email_address, :phone, presence: true
  validates :password, length: { minimum: 8 }
  validates :terms, acceptance: { accept: true, message: "must be accepted" }
  validate :phone_valid

  def save
    return false unless valid?
    ActiveRecord::Base.transaction do
      @vendor = Vendor.create!(business_name:, phone:, email: email_address)
      @user = User.create!(name:, email_address:, phone:, password:, role: "vendor_owner", vendor: @vendor)
    end
    UserMailer.email_verification(@user).deliver_later
    Notifier.notify(Notifier.platform_admins, kind: "vendor", title: "New vendor application: #{business_name}", body: city)
    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |err| errors.add(err.attribute == :email_address ? :email_address : :base, err.message) }
    false
  end

  private

  def phone_valid
    errors.add(:phone, "is not a valid phone number") if phone.present? && !Phonelib.valid_for_country?(phone, "IN")
  end
end
