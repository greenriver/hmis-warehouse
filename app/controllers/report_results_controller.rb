###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportResultsController < ApplicationController
  before_action :require_can_view_hud_reports!
  before_action :set_report
  before_action :set_report_result, only: [:show, :edit, :update, :destroy]
  helper_method :sort_column, :sort_direction
  helper_method :default_pit_date, :default_chronic_date
  include ArelHelper

  # GET /report_results
  def index
    @results = report_result_scope.select(*report_result_summary_columns)

    set_missing_data if @report.class.name.include?('::Lsa::')

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
        send_data file.content, filename: "#{filename}-#{@result.created_at.strftime('%Y-%m-%dT%H%M')}.zip", type: file.content_type, disposition: 'attachment'
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
      options[:pit_date] = pit_date
      options[:chronic_date] = chronic_date
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
    ), queue: :long_running
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

  private

  def missing_data_columns
    {
      project_name: p_t[:ProjectName].to_sql,
      org_name: o_t[:OrganizationName].to_sql,
      project_type: p_t[:computed_project_type].to_sql,
      funder: f_t[:Funder].to_sql,
      id: p_t[:id].to_sql,
      ds_id: p_t[:data_source_id].to_sql,
    }
  end

  def set_missing_data
    @missing_data = {
      missing_housing_type: [],
      missing_geocode: [],
      missing_geography_type: [],
      missing_zip: [],
      missing_operating_start_date: [],
      invalid_funders: [],
    }
    range = ::Filters::DateRange.new(start: Date.current - 3.years, end: Date.current)

    # There are a few required project descriptor fields.  Without these the report won't run cleanly
    @missing_data[:missing_housing_type] = GrdaWarehouse::Hud::Project.joins(:organization).
      includes(:funders).
      where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
      where(HousingType: nil, housing_type_override: nil).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end

    @missing_data[:missing_geocode] = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Geocode: nil, geocode_override: nil).
      pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end

    @missing_data[:missing_geography_type] = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(GeographyType: nil, geography_type_override: nil).
      pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end

    query = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Zip: nil, zip_override: nil)
    @missing_data[:missing_zip] = query.pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end

    @missing_data[:missing_operating_start_date] = GrdaWarehouse::Hud::Project.joins(:organization).
      includes(:funders).
      where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
      where(OperatingStartDate: nil, operating_start_date_override: nil).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end
    @missing_data[:invalid_funders] = GrdaWarehouse::Hud::Project.joins(:organization).
      includes(:funders).
      distinct.
      # merge(GrdaWarehouse::Hud::Project.coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)).
      where(f_t[:Funder].not_in(::HUD.funding_sources.keys)).
      pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end
    query = GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(CoCCode: nil, hud_coc_code: nil)
    @missing_data[:missing_coc_codes] = query.pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end

    @missing_projects = @missing_data.values.flatten.uniq.sort_by(&:first)
    @show_missing_data = @missing_projects.any?
  end

  def report_result_scope
    report_result_source.viewable_by(current_user).
      joins(:user).
      where(report_id: params[:report_id].to_i)
  end

  def report_result_summary_columns
    report_result_source.column_names - ['original_results', 'results', 'support', 'validations']
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_report_result
    @result = report_result_scope.find(params[:id].to_i)
  end

  def report_result_source
    ReportResult
  end

  def set_report
    @report = Report.find(params[:report_id].to_i)
  end

  # Only allow a trusted parameter "white list" through.
  def report_result_params
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
        coc_codes: [],
        project_id: [],
        project_type: [],
        project_group_ids: [],
      ],
    )
  end

  def sort_column
    report_result_source.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def default_pit_date
    'Jan 31, 2018'
  end

  def default_chronic_date
    'Jan 31, 2018'
  end
end
