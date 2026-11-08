class Current < ActiveSupport::CurrentAttributes
  attribute :session, :company, :vendor
  delegate :user, to: :session, allow_nil: true
end
