class Admin::BaseController < ApplicationController
  include Portal
  layout "admin"
  portal_roles User::PLATFORM_ROLES
end
