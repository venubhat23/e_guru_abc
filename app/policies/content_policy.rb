# Website content (occasions, FAQs, legal pages): ops & super admins manage it.
class ContentPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def create? = ops?
  def update? = ops?
  def destroy? = ops?

  class Scope < Scope
    def resolve = user&.platform? ? scope.all : scope.none
  end
end
