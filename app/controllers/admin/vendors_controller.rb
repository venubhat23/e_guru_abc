class Admin::VendorsController < Admin::BaseController
  before_action :set_vendor, except: :index

  def index
    scope = policy_scope(Vendor)
    @counts = policy_scope(Vendor).group(:status).count
    @status = params[:status].presence_in(%w[pending approved rejected suspended])
    scope = scope.where(status: @status) if @status
    scope = scope.where("business_name ILIKE :q OR gstin ILIKE :q", q: "%#{Vendor.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @pagy, @vendors = pagy(scope.order(Arel.sql("CASE status WHEN 'pending' THEN 0 ELSE 1 END"), :business_name))
    @offer_counts = VendorOffer.where(vendor_id: @vendors.map(&:id)).group(:vendor_id).count
    @region_counts = VendorRegion.where(vendor_id: @vendors.map(&:id)).group(:vendor_id).count
  end

  def show
    authorize @vendor
    @offers = @vendor.offers.includes(:offerable).order(:offerable_type, :id)
    @performance = @vendor.performance
    @assignments = @vendor.assignments.includes(:booking).order(created_at: :desc).limit(8)
    @payout_totals = @vendor.payouts.group(:status).sum(:amount_paise)
  end

  def edit = authorize(@vendor)

  def update
    authorize @vendor
    if @vendor.update(vendor_params)
      redirect_to admin_vendor_path(@vendor), notice: "Vendor updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def approve
    authorize @vendor
    if @vendor.may_approve?
      @vendor.approve!
      Notifier.notify(@vendor.users.active, kind: "vendor", title: "You're approved on Avighna eGiftMitra 🎉", body: "Start adding offers from the master catalogue.", url: "/vendor", email: true)
      redirect_to admin_vendor_path(@vendor), notice: "#{@vendor.name} approved."
    else
      redirect_to admin_vendor_path(@vendor), alert: "Can't approve yet — missing: #{@vendor.kyc_missing.to_sentence}."
    end
  end

  def reject
    authorize @vendor
    @vendor.rejection_reason = params[:reason]
    return redirect_to(admin_vendor_path(@vendor), alert: "Give a rejection reason.") unless @vendor.may_reject?
    @vendor.reject!
    Notifier.notify(@vendor.users.active, kind: "vendor", title: "Your vendor application was not approved", body: @vendor.rejection_reason, url: "/vendor", email: true)
    redirect_to admin_vendor_path(@vendor), notice: "Application rejected."
  end

  def suspend
    authorize @vendor
    @vendor.suspension_reason = params[:reason]
    return redirect_to(admin_vendor_path(@vendor), alert: "Give a suspension reason.") unless @vendor.may_suspend?
    @vendor.suspend!
    @vendor.offers.update_all(active: false)
    redirect_to admin_vendor_path(@vendor), notice: "#{@vendor.name} suspended and its offers paused."
  end

  private

  def set_vendor = @vendor = policy_scope(Vendor).find(params[:id])

  def vendor_params
    params.require(:vendor).permit(:business_name, :legal_name, :contact_name, :email, :phone, :gstin, :pan, :fssai_number, :warehouse_address,
                                   :warehouse_city, :warehouse_state, :warehouse_pincode, :bank_account_name, :bank_account_number, :bank_ifsc, :rating)
  end
end
