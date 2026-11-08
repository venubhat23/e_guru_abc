class Hr::CompaniesController < Hr::BaseController
  def show
    @company = Current.company
    authorize @company
  end
end
