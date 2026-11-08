class LeadPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
  def update? = ops?
  def transition? = ops?
  def convert? = ops? && !record.converted? && record.status != "lost"
  def add_note? = platform?

  class Scope < Scope
    def resolve = user&.platform? ? scope.all : scope.none
  end
end
