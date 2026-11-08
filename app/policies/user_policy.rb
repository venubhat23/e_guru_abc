# Users are visible only within the same tenant (company or vendor); platform admins see all.
class UserPolicy < ApplicationPolicy
  def index? = platform? || user.hr? || user.vendor_user?
  def show? = Scope.new(user, User).resolve.exists?(record.id)

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(company_id: user.company_id) if user.hr?
      return scope.where(vendor_id: user.vendor_id) if user.vendor_user?
      scope.none
    end
  end
end
