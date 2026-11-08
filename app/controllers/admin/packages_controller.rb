class Admin::PackagesController < Admin::BaseController
  before_action :set_package, except: %i[index new create]

  def index
    scope = policy_scope(Package).includes(:occasion, package_items: :product)
    scope = scope.where(occasion_id: params[:occasion_id]) if params[:occasion_id].present?
    @pagy, @packages = pagy(scope.ordered)
    @occasions = Occasion.ordered
    @calc = Pricing::Calculator.new
  end

  def show
    authorize @package
    @calc = Pricing::Calculator.new
    @offers = @package.vendor_offers.includes(vendor: :regions).order(:vendor_price_paise)
  end

  def new
    @package = Package.new(min_qty: 25)
    3.times { @package.package_items.build(quantity: 1) }
    authorize @package
    load_form
  end

  def create
    @package = Package.new(package_params)
    authorize @package
    if @package.save
      redirect_to admin_package_path(@package), notice: "Package created."
    else
      load_form
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @package
    @package.package_items.build(quantity: 1)
    load_form
  end

  def update
    authorize @package
    if @package.update(package_params)
      redirect_to admin_package_path(@package), notice: "Package saved."
    else
      load_form
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @package
    @package.destroy ? redirect_to(admin_packages_path, notice: "Package deleted.") : redirect_to(admin_package_path(@package), alert: @package.errors.full_messages.to_sentence)
  end

  private

  def set_package = @package = policy_scope(Package).includes(package_items: { product: :category }).find_by!(slug: params[:id])
  def load_form = (@products = Product.sellable.ordered; @occasions = Occasion.ordered)

  def package_params
    params.require(:package).permit(:occasion_id, :name, :slug, :description, :min_qty, :emoji, :active, images: [],
                                    package_items_attributes: %i[id product_id quantity _destroy]).tap do |p|
      p.delete(:images) if p[:images].blank? || p[:images].all?(&:blank?)
    end
  end
end
