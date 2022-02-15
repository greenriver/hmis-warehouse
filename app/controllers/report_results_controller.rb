###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportResultsController < ApplicationController
  before_action :require_can_view_hud_reports!
  before_action :set_report
  before_action :set_report_result, only: [:show, :edit, :update, :destroy, :download_support]
  helper_method :sort_column, :sort_direction
  helper_method :default_pit_date, :default_chronic_date
  include ArelHelper

  # GET /report_results
  def index
    @results = report_result_scope.select(*report_result_summary_columns)

    @missing_data = @report.missing_data(current_user) if @report.respond_to?(:missing_data)

    at = @results.arel_table
    # sort / paginate
    sort = at[sort_column.to_sym].send(sort_direction)
    @results = @results.
      order(sort).
      page(params[:page].to_i).per(20)
  end

  # GET /report_results/new
  def new
    @result = report_result_source.new
  end

  def show
    respond_to do |format|
      format.html {} # render the default template
      format.csv do
        unless @result.results.present?
          flash[:alert] = "There are no results to show for #{@report.name}"
          redirect_to action: :show
        end
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@report.name}-#{@result.created_at.strftime('%Y-%m-%dT%H%M ')}.csv\""
      end
      format.xml do
        unless @result.results.present?
          flash[:alert] = "There are no results to show for #{@report.name}"
          redirect_to action: :show
        end
        response.headers['Content-Type'] = 'text/xml'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@report.name}-#{@result.created_at.strftime('%Y-%m-%dT%H%M ')}.xml\""
      end
      format.zip do
        if @result.file_id.blank? || @result.download_type != :zip
          flash[:alert] = "Unable to download zip file for #{@report.name}"
          redirect_to action: :show
        end
        file = @result.file.first
        filename = @report.try(:file_name, @result.options) || @report.name
        send_data file.content, filename: "#{filename}-#{@result.created_at.to_s(:db)}.zip", type: file.content_type, disposition: 'attachment'
      end
    end
  end

  def download_support
    respond_to do |format|
      format.zip do
        if @result.support_file_id.blank?
          flash[:alert] = "Unable to download support file for #{@report.name}"
          redirect_to action: :show
        end
        file = @result.support_file
        filename = @report.try(:file_name, @result.options) || @report.name
        send_data file.content, filename: "Support for #{filename}-#{@result.created_at.to_s(:db)}.zip", type: file.content_type, disposition: 'attachment'
      end
    end
  end

  # POST /report_results
  def create
    run_report_engine = false
    @result = report_result_source.new(report: @report, percent_complete: 0.0, user_id: current_user.id)
    @result.options = report_result_params['options'] if @report.has_options?
    if @result.save!
      run_report_engine = true
      flash[:notice] = _('Report queued to start.')
      redirect_to action: :index
    else
      flash[:error] = _('Report failed to queue.')
      redirect_to action: :index
      return
    end
    options = { user_id: current_user.id }
    if @report.has_project_option?
      p_id, ds_id = JSON.parse(@result.options['project'])
      options[:project] = p_id
      options[:data_source_id] = ds_id
    end
    if @report.has_data_source_option?
      ds_id = @result.options['data_source'].to_i
      options[:data_source_id] = ds_id
    end
    if @report.has_pit_options?
      pit_date = @result.options['pit_date'].to_date
      chronic_date = @result.options['chronic_date'].to_date
      project_ids = @result.options.try(:[], 'project_ids')&.reject(&:blank?)&.map(&:to_i) || []
      project_group_ids = @result.options.try(:[], 'project_group_ids')&.reject(&:blank?)&.map(&:to_i) || []
      project_ids += GrdaWarehouse::ProjectGroup.
        joins(:projects).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        where(id: project_group_ids).pluck(p_t[:id])
      options[:pit_date] = pit_date
      options[:chronic_date] = chronic_date
      options[:project_ids] = project_ids
    end
    if @report.has_date_range_options?
      report_start = @result.options['report_start'].to_date
      report_end = @result.options['report_end'].to_date
      options[:report_start] = report_start
      options[:report_end] = report_end
    end
    if @report.has_coc_codes_option? && @result.options['coc_codes'].present?
      coc_codes = @result.options['coc_codes'].select(&:present?)
      options[:coc_codes] = coc_codes
    end
    return unless run_report_engine

    job = Delayed::Job.enqueue Reporting::RunReportJob.new(
      report: @report,
      result_id: @result.id,
      options: options,
    ), queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
    @result.update(delayed_job_id: job.id)
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
    flash[:notice] = _('Report successfully removed.')
    redirect_to report_report_results_url
  end

  private def report_result_scope
    report_result_source.viewable_by(current_user).
      joins(:user).
      where(report_id: params[:report_id].to_i)
  end

  private def report_result_summary_columns
    report_result_source.column_names - ['original_results', 'results', 'support', 'validations']
  end

  # Use callbacks to share common setup or constraints between actions.
  private def set_report_result
    @result = report_result_scope.find(params[:id].to_i)
  end

  private def report_result_source
    ReportResult
  end

  private def set_report
    @report = Report.find(params[:report_id].to_i)
  end

  # Only allow a trusted parameter "white list" through.
  private def report_result_params
    params.require(:report_result).permit(
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
        :sub_population,
        :race_code,
        :ethnicity_code,
        :lsa_scope,
        data_source_ids: [],
        coc_codes: [],
        project_id: [],
        project_ids: [],
        project_type: [],
        project_group_ids: [],
      ],
    )
  end

  private def sort_column
    report_result_source.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  private def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  private def default_pit_date
    'Jan 31, 2018'
  end

  private def default_chronic_date
    'Jan 31, 2018'
  end
end
