# In-app bell notifications, optionally with an email per recipient.
class Notifier
  def self.notify(users, title:, body: nil, url: nil, kind: nil, email: false)
    users = Array(users).compact.uniq
    return if users.empty?
    now = Time.current
    Notification.insert_all(users.map { |u| { user_id: u.id, title:, body:, url:, kind:, created_at: now, updated_at: now } })
    users.each { |u| NotificationMailer.event(u, title:, body:, url:).deliver_later } if email
  end

  def self.platform_admins(roles: %w[super_admin ops_admin]) = User.active.where(role: roles)
  def self.finance = User.active.where(role: %w[super_admin finance_admin])
end
