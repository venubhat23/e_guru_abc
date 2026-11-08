# Expires assignments past their SLA: releases capacity and returns bookings to assigning.
class AssignmentSlaJob < ApplicationJob
  queue_as :default

  def perform
    Assignment.sla_breached.find_each { |a| Assignment::Workflow.expire!(a) }
  end
end
