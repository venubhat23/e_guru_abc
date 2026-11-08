class Admin::TicketsController < Admin::BaseController
  before_action :set_ticket, except: :index

  def index
    base = policy_scope(Ticket)
    @counts = base.group(:status).count
    scope = base.includes(:company, :booking, :assignee, :booking_recipient)
    scope = scope.where(status: params[:status]) if params[:status].in?(%w[open in_progress resolved closed])
    scope = scope.unresolved if params[:status].blank?
    scope = scope.where(priority: params[:priority]) if params[:priority].in?(Ticket::PRIORITIES)
    scope = scope.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    @pagy, @tickets = pagy(scope.order(Arel.sql("CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END"), created_at: :desc))
    @admins = User.platform.active.ordered
  end

  def show
    authorize @ticket
    @admins = User.platform.active.ordered
  end

  def update
    authorize @ticket
    @ticket.update(params.require(:ticket).permit(:assignee_id, :priority, :resolution)) ? redirect_to(admin_ticket_path(@ticket), notice: "Ticket updated.") : redirect_to(admin_ticket_path(@ticket), alert: @ticket.errors.full_messages.to_sentence)
  end

  def transition
    authorize @ticket
    event = params[:event].to_s.presence_in(%w[start resolve close reopen])
    @ticket.resolution = params[:resolution] if params[:resolution].present?
    if event && @ticket.public_send(:"may_#{event}?")
      @ticket.public_send(:"#{event}!")
      Notifier.notify(@ticket.raised_by, kind: "ticket", title: "Ticket #{@ticket.number} is #{@ticket.status.humanize.downcase}", body: @ticket.resolution, url: "/hr", email: true) if @ticket.resolved?
      redirect_to admin_ticket_path(@ticket), notice: "Ticket #{@ticket.status.humanize.downcase}."
    else
      redirect_to admin_ticket_path(@ticket), alert: event == "resolve" ? "Add a resolution note first." : "That change isn't allowed."
    end
  end

  private

  def set_ticket = @ticket = policy_scope(Ticket).find(params[:id])
end
