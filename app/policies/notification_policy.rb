class NotificationPolicy < ApplicationPolicy
  def update? = record.user_id == user.id

  class Scope < Scope
    def resolve = scope.where(user:)
  end
end
