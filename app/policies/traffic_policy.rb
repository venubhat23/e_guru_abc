class TrafficPolicy < ApplicationPolicy
  def show? = super_admin?
end
