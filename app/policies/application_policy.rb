# Deny by default. Platform roles are checked with the helpers below.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def super_admin? = user&.super_admin?
  def ops? = user&.super_admin? || user&.ops_admin?
  def finance? = user&.super_admin? || user&.finance_admin?
  def platform? = user&.platform?

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve = scope.none

    private

    attr_reader :user, :scope
  end
end
