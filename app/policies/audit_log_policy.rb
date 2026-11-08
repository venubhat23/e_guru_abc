class AuditLogPolicy < ApplicationPolicy
  def index? = super_admin? || user&.finance_admin?

  class Scope < Scope
    def resolve = (user&.super_admin? || user&.finance_admin?) ? scope.all : scope.none
  end
end
