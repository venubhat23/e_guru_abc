# Base for the marketing site: no login needed, public layout.
class PublicController < ApplicationController
  include TrafficTracking
  allow_unauthenticated_access
  layout "public"
  before_action :resume_session
end
