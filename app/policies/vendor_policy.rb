class VendorPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def update? = ops?
  def approve? = ops?
  def reject? = ops?
  def suspend? = ops?

  class Scope < Scope
    def resolve = user&.platform? ? scope.all : scope.none
  end
end
