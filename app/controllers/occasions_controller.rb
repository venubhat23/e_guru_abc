class OccasionsController < PublicController
  def show
    @occasion = Occasion.active.find_by!(slug: params[:id])
    @others = Occasion.active.ordered.where.not(id: @occasion.id)
  end
end
