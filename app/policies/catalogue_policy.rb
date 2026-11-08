# Categories, products and packages.
class CataloguePolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def create? = ops?
  def update? = ops?
  def destroy? = ops?
  def review? = ops?

  class Scope < Scope
    def resolve = user&.platform? ? scope.all : scope.none
  end
end
