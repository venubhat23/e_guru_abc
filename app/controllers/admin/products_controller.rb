class Admin::ProductsController < Admin::BaseController
  before_action :set_product, except: %i[index new create]

  def index
    scope = policy_scope(Product).includes(category: :parent)
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = scope.where(review_status: params[:review]) if params[:review].in?(Product::REVIEW_STATUSES)
    scope = scope.where("products.name ILIKE :q OR products.sku ILIKE :q", q: "%#{Product.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @pagy, @products = pagy(scope.order(:name), limit: 25)
    @categories = Category.ordered
    @calc = Pricing::Calculator.new
    @lowest = VendorOffer.active.from_approved_vendors.where(offerable_type: "Product", offerable_id: @products.map(&:id)).group(:offerable_id).minimum(:vendor_price_paise)
  end

  def show
    authorize @product
    @calc = Pricing::Calculator.new
    @offers = @product.vendor_offers.includes(:vendor).order(:vendor_price_paise)
  end

  def new
    @product = Product.new(gst_rate: 18, volume_units: 1)
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product
    @product.save ? redirect_to(admin_product_path(@product), notice: "Product created.") : render(:new, status: :unprocessable_content)
  end

  def edit = authorize(@product)

  def update
    authorize @product
    @product.update(product_params) ? redirect_to(admin_product_path(@product), notice: "Product saved.") : render(:edit, status: :unprocessable_content)
  end

  def destroy
    authorize @product
    @product.destroy ? redirect_to(admin_products_path, notice: "Product deleted.") : redirect_to(admin_product_path(@product), alert: @product.errors.full_messages.to_sentence)
  end

  # Approve or reject a vendor-proposed product.
  def review
    authorize @product
    decision = params[:decision].presence_in(%w[approved rejected])
    return redirect_to(admin_product_path(@product), alert: "Choose approve or reject.") unless decision
    @product.update!(review_status: decision, review_note: params[:note])
    if @product.proposed_by_vendor
      Notifier.notify(@product.proposed_by_vendor.users.active, kind: "catalogue", title: "Your product proposal \"#{@product.name}\" was #{decision}",
                      body: params[:note], url: "/vendor", email: true)
    end
    redirect_to admin_product_path(@product), notice: "Product #{decision}."
  end

  private

  def set_product = @product = policy_scope(Product).find(params[:id])

  def product_params
    attrs = params.require(:product).permit(:category_id, :sku, :name, :description, :hsn_code, :gst_rate, :volume_units, :brandable,
                                            :markup_override_pct, :emoji, :active, :variants_text, images: [])
    if attrs.key?(:variants_text)
      text = attrs.delete(:variants_text)
      attrs[:variants] = text.to_s.lines.filter_map { |l| k, v = l.split(":", 2); [ k.strip, v.split(",").map(&:strip) ] if v }.to_h
    end
    attrs.delete(:images) if attrs[:images].blank? || attrs[:images].all?(&:blank?)
    attrs
  end
end
