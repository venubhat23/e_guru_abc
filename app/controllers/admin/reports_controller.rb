class Admin::ReportsController < Admin::BaseController
  def index
    authorize :report, :index?
    skip_policy_scope
    @reports = Reports::Builder::REPORTS
  end

  def show
    authorize :report, :show?
    from = (Date.parse(params[:from]) rescue 12.months.ago.to_date.beginning_of_month)
    to = (Date.parse(params[:to]) rescue Date.current)
    @from, @to = from, to
    @report = Reports::Builder.new(params[:id], from: from.beginning_of_day, to: to.end_of_day).call
    respond_to do |format|
      format.html
      format.csv { send_data @report.to_csv, filename: "#{@report.key}-#{from}-#{to}.csv", type: "text/csv" }
    end
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound
  end
end
