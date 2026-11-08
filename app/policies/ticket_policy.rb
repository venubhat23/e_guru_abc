class TicketPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def update? = ops?
  def transition? = ops?
  def comment? = platform?

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(company_id: user.company_id) if user.hr?
      scope.none
    end
  end
end
