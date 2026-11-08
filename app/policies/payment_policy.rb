class PaymentPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def verify? = finance? && record.pending?
  def reject? = verify?

  class Scope < Scope
    def resolve = user&.platform? ? scope.all : scope.none
  end
end
