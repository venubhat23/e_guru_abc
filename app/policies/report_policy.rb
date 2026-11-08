class ReportPolicy < ApplicationPolicy
  def index? = platform?
  def show? = platform?
end
