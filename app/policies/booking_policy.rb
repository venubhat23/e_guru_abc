class BookingPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def operate? = ops?
  %i[auto_assign? manual_assign? cancel? confirm_delivery? dispute? resolve_dispute?].each { alias_method _1, :operate? }
  def proforma? = platform?
  def delivery_report? = platform?

  class Scope < Scope
    def resolve
      return scope.all if user.platform?
      return scope.where(company_id: user.company_id) if user.hr?
      scope.none
    end
  end
end
