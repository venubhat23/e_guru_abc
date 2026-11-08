class AssignmentPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def expire? = ops?
  def packing_list? = platform?
  def labels? = platform?

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(vendor_id: user.vendor_id) if user.vendor_user?
      scope.none
    end
  end
end
