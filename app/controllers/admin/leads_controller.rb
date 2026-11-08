class Admin::LeadsController < Admin::BaseController
  before_action :set_lead, except: :index

  def index
    scope = policy_scope(Lead).includes(:occasion, :owner)
    @counts = scope.unscope(:includes).group(:status).count
    scope = scope.where(status: params[:status]) if Lead::STATUS_LABELS.key?(params[:status])
    scope = scope.search(params[:q]) if params[:q].present?
    scope = scope.where(owner_id: params[:owner_id]) if params[:owner_id].present?
    scope = scope.where(occasion_id: params[:occasion_id]) if params[:occasion_id].present?
    scope = scope.follow_up_due if params[:follow_up] == "due"
    @pagy, @leads = pagy(scope.recent, limit: 20)
    @owners = User.platform.active.ordered
    @occasions = Occasion.ordered
  end

  def show
    authorize @lead
    @activities = @lead.activities.includes(:user).limit(50)
    @owners = User.platform.active.ordered
    @note = @lead.activities.build(kind: "note")
  end

  def update
    authorize @lead
    @lead.actor = current_user
    old_owner, old_follow_up = @lead.owner, @lead.follow_up_on
    if @lead.update(lead_params)
      @lead.log!("owner_change", "Owner set to #{@lead.owner&.name || 'nobody'}") if @lead.owner != old_owner
      @lead.log!("follow_up", "Follow-up set for #{@lead.follow_up_on&.to_fs(:long) || 'none'}") if @lead.follow_up_on != old_follow_up
      redirect_to admin_lead_path(@lead), notice: "Lead updated."
    else
      redirect_to admin_lead_path(@lead), alert: @lead.errors.full_messages.to_sentence
    end
  end

  def transition
    authorize @lead
    event = params[:event].to_s.to_sym
    unless Lead::EVENT_LABELS.key?(event) && @lead.available_events.include?(event)
      return redirect_to(admin_lead_path(@lead), alert: "That status change isn't allowed.")
    end
    @lead.actor = current_user
    @lead.lost_reason = params[:lost_reason] if event == :mark_lost
    if @lead.public_send(:"may_#{event}?")
      @lead.public_send(:"#{event}!")
      redirect_to admin_lead_path(@lead), notice: "Lead moved to #{@lead.status_label}."
    else
      redirect_to admin_lead_path(@lead), alert: event == :mark_lost ? "Please give a reason for losing this lead." : "Could not change status."
    end
  rescue AASM::InvalidTransition, ActiveRecord::RecordInvalid => e
    redirect_to admin_lead_path(@lead), alert: e.message
  end

  def convert
    authorize @lead
    company = Leads::Converter.call(lead: @lead, actor: current_user, attributes: params.fetch(:company, {}).permit(:legal_name, :gstin, :state))
    redirect_to admin_company_path(company), notice: "#{company.legal_name} created from lead. 🎉"
  rescue Leads::Converter::Error, ActiveRecord::RecordInvalid => e
    redirect_to admin_lead_path(@lead), alert: e.message
  end

  private

  def set_lead = @lead = policy_scope(Lead).find(params[:id])
  def lead_params = params.require(:lead).permit(:owner_id, :follow_up_on)
end
