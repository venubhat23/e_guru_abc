class VendorPayoutPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def approve? = finance? && record.due?
  def pay? = finance? && record.approved?

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(vendor_id: user.vendor_id) if user.vendor_user?
      scope.none
    end
  end
end
