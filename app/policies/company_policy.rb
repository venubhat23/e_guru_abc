class CompanyPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform? || (user.hr? && record.id == user.company_id)
  def update? = ops? || (user.hr_admin? && record.id == user.company_id)

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(id: user.company_id) if user.hr?
      scope.none
    end
  end
end
