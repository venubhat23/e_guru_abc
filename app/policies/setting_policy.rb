class SettingPolicy < ApplicationPolicy
  def index? = platform?
  def update? = super_admin?
end
