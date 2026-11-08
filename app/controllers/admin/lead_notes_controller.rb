class Admin::LeadNotesController < Admin::BaseController
  def create
    lead = policy_scope(Lead).find(params[:lead_id])
    authorize lead, :add_note?
    activity = lead.activities.build(kind: "note", body: params.dig(:lead_activity, :body), user: current_user)
    if activity.save
      redirect_to admin_lead_path(lead, anchor: "activity"), notice: "Note added."
    else
      redirect_to admin_lead_path(lead), alert: "Note can't be blank."
    end
  end
end
