class Admin::LegalPagesController < Admin::ContentController
  private

  def model = LegalPage
  def order_by = :title
  def permitted_attributes = %i[title slug summary body effective_on published]
end
