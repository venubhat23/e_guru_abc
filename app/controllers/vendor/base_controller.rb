# Every vendor request is scoped to the signed-in user's vendor (Current.vendor).
class Vendor::BaseController < ApplicationController
  include Portal
  layout "vendor"
  portal_roles User::VENDOR_ROLES
  before_action { Current.vendor = current_user.vendor }
end
