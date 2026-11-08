class ContactsController < PublicController
  HONEYPOT = :website

  def new
    @lead = Lead.new(occasion: Occasion.active.find_by(slug: params[:occasion]))
    @occasions = Occasion.active.ordered
  end

  def create
    # Bots fill the hidden field: pretend success, store nothing.
    return redirect_to(thanks_contact_path) if params.dig(:lead, HONEYPOT).present?

    result = Leads::Intake.call(params: lead_params, request:)
    if result.success?
      session[:lead_name] = result.lead.name.split.first
      redirect_to thanks_contact_path
    else
      @lead = result.lead
      @occasions = Occasion.active.ordered
      render :new, status: :unprocessable_content
    end
  end

  def thanks
    @name = session.delete(:lead_name)
  end

  private

  def lead_params
    params.require(:lead).permit(:name, :work_email, :phone, :company_name, :employee_count, :occasion_id,
                                 :budget_per_employee_rupees, :message, :consent)
  end
end
