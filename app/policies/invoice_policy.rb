class InvoicePolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform? || (user.hr? && record.company_id == user.company_id)

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(company_id: user.company_id) if user.hr?
      scope.none
    end
  end
end
