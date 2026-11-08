class Admin::FaqsController < Admin::ContentController
  private

  def model = Faq
  def order_by = %i[audience position id]
  def permitted_attributes = %i[question answer audience position active]
end
