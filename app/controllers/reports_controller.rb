class ReportsController < ApplicationController
  before_action :require_can_view_reports!
  before_action :set_report, only: [:show, :edit, :update, :destroy]
  helper_method :sort_column, :sort_direction

  # GET /services
  def index
    @reports = report_scope.order(weight: :asc)
    @reports = group_reports(@reports)
  end

    # GET /services/new
  def new
    @report = report_source.new
  end

  # GET /services/1/edit
  def edit
  end

  # POST /services
  def create
    @report = report_source.new(report_params)

    if @report.save
      redirect_to action: :index
      flash[:notice] = "#{Report.model_name.human} <strong>#{@report.name}</strong> was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /services/1
  def update
    if @report.update(report_params)
      redirect_to action: :index
      flash[:notice] = "#{Report.model_name.human} <strong>#{@report.name}</strong> was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /services/1
  def destroy
    @report.destroy
    redirect_to reports_url, notice: "#{Report.model_name.human} <strong>#{@report.name}</strong> was successfully destroyed."
  end

  private
    def report_source
      Report
    end

    def report_scope
      Report.all
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_report
      @report = Report.find(params[:id].to_i)
    end

    # Only allow a trusted parameter "white list" through.
    def report_params
      params.require(:report).permit(
        :name,
      )
    end

    def sort_column
      report_source.column_names.include?(params[:sort]) ? params[:sort] : 'name'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    def group_reports reports
      reports.group_by{|r|
        r.type.split('::')[0...-1].join('::')}
    end
end
