class Admin::TicketCommentsController < Admin::BaseController
  def create
    ticket = policy_scope(Ticket).find(params[:ticket_id])
    authorize ticket, :comment?
    comment = ticket.comments.build(user: current_user, body: params.dig(:ticket_comment, :body), internal: params.dig(:ticket_comment, :internal) == "1")
    comment.save ? redirect_to(admin_ticket_path(ticket, anchor: "comments"), notice: "Comment added.") : redirect_to(admin_ticket_path(ticket), alert: "Comment can't be blank.")
  end
end
