class ReportResultsController < ApplicationController
  before_action :require_can_view_reports!
  before_action :set_report
  before_action :set_report_result, only: [:show, :edit, :update, :destroy]
  helper_method :sort_column, :sort_direction
  helper_method :default_pit_date, :default_chronic_date

  # GET /report_results
  def index
    @results = report_result_scope
    at = @results.arel_table
    # sort / paginate
    sort = at[sort_column.to_sym].send(sort_direction)
    @results = @results
      .order(sort)
      .page(params[:page].to_i).per(20)
  end

    # GET /report_results/new
  def new
    @result = report_result_source.new
  end

  def show
    respond_to do |format|
      format.html { } # render the default template
      format.csv do
        unless @result.results.present?
          flash[:alert] = "There are no results to show for #{@report.name}"
          redirect_to action: :show
        end
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@report.name}-#{@result.created_at}.csv\""
      end
      format.xml do
        unless @result.results.present?
          flash[:alert] = "There are no results to show for #{@report.name}"
          redirect_to action: :show
        end
        response.headers['Content-Type'] = 'text/xml'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@report.name}-#{@result.created_at}.xml\""
      end
    end
  end

  # POST /report_results
  def create

    run_report_engine = false
    @result = report_result_source.new(report: @report, percent_complete: 0.0, user_id: current_user.id)
    if @report.has_options?
      @result.options = report_result_params['options']
    end
    if @result.save!
      run_report_engine = true
      flash[:notice] = _('Report queued to start.')
      redirect_to action: :index
    else
      flash[:error] = _('Report failed to queue.')
      redirect_to action: :index
      return
    end
    options = {}
    if @report.has_project_option?
      p_id, ds_id = JSON.parse(@result.options['project'])
      options.merge!({project: p_id, data_source_id: ds_id})
    end
    if @report.has_data_source_option?
      ds_id = @result.options['data_source'].to_i
      options.merge!({data_source_id: ds_id})
    end
    if @report.has_pit_options?
      pit_date = @result.options['pit_date'].to_date
      chronic_date = @result.options['chronic_date'].to_date
      options.merge!({pit_date: pit_date, chronic_date: chronic_date})
    end
    if @report.has_date_range_options?
      report_start = @result.options['report_start'].to_date
      report_end = @result.options['report_end'].to_date
      options.merge!({report_start: report_start, report_end: report_end})
    end
    if run_report_engine
      job = Delayed::Job.enqueue Reporting::RunReportJob.new(
        report: @report, 
        result_id: @result.id, 
        options: options
      ), queue: :default_priority
      @result.update(delayed_job_id: job.id)
    end
  end

  # PATCH/PUT /report_results/1
  def update
    if @result.update(report_result_params)
      redirect_to action: :index
      flash[:notice] = _('Report successfully updated.')
    else
      render :edit
    end
  end

  # DELETE /report_results/1
  def destroy
    @result.destroy
    flash[:notice] = _('Report successfully destroyed.')
    redirect_to report_report_results_url
  end

  private
    def report_result_source
      ReportResult
    end

    def report_result_scope
      ReportResult.where(report_id: params[:report_id].to_i)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_report_result
      @result = ReportResult.find(params[:id].to_i)
    end

    def set_report
      @report = Report.find(params[:report_id].to_i)
    end

    # Only allow a trusted parameter "white list" through.
    def report_result_params
      allowed_params = params.require(:report_result).permit(
        :name,
        options: [
          :project, 
          :data_source, 
          :pit_date, 
          :chronic_date, 
          :report_start, 
          :report_end,
          :data_source_id,
          :coc_code,
          project_id: [],
          project_type:[],
        ],
        results: ReportGenerators::Ahar::Fy2016::Base.questions,
      )
      
    end

    def sort_column
      report_result_source.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    def default_pit_date
      'Jan 25, 2017'
    end
    
    def default_chronic_date
      'Jan 25, 2017'
    end
end
