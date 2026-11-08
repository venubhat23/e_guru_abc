# Generic CRUD for simple website content models (occasions, FAQs, legal pages).
class Admin::ContentController < Admin::BaseController
  before_action :set_record, only: %i[edit update destroy]

  def index
    @pagy, @records = pagy(policy_scope(model).order(order_by), limit: 25)
  end

  def new
    @record = model.new
    authorize @record
  end

  def create
    @record = model.new(permitted)
    authorize @record
    if @record.save
      redirect_to [ :admin, model ], notice: "#{model.model_name.human} created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit = authorize(@record)

  def update
    authorize @record
    if @record.update(permitted)
      redirect_to [ :admin, model ], notice: "#{model.model_name.human} saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @record
    @record.destroy ? redirect_to([ :admin, model ], notice: "Deleted.") : redirect_to([ :admin, model ], alert: @record.errors.full_messages.to_sentence)
  end

  private

  def set_record = @record = policy_scope(model).find_by!(model.column_names.include?("slug") ? { slug: params[:id] } : { id: params[:id] })
  def permitted = params.require(model.model_name.param_key).permit(*permitted_attributes)
  def order_by = :id
end
