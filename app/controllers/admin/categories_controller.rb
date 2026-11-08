class Admin::CategoriesController < Admin::ContentController
  private

  def model = Category
  def order_by = %i[position name]
  def set_record = @record = policy_scope(Category).find(params[:id])
  def permitted_attributes = %i[name slug parent_id markup_override_pct food emoji position]
end
