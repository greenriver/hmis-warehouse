module WarehouseReports
  class InitiativesController < ApplicationController
    include PjaxModalController
    include WarehouseReportAuthorization
    # Authorize by either access to report OR access by token
    skip_before_action :authenticate_user!
    skip_before_action :require_can_view_any_reports!
    before_action :set_report, only: [:show, :destroy]
    before_action :set_jobs, only: [:index, :running, :create]
    before_action :set_reports, only: [:index, :running, :create]

    def index
      @filter = ::Filters::Initiative.new()
    end

    def running

    end

    def set_jobs
      @job_reports = Delayed::Job.where(queue: :initiative_reports).order(run_at: :desc).map do |job|
        parameters = YAML.load(job.handler).job_data['arguments'].first
        parameters.delete('_aj_symbol_keys')
        parameters['project_ids'] = parameters.delete('projects')
        report = WarehouseReports::InitiativeReportJob.new(parameters)
        [job.run_at, report]
      end
    end

    def set_reports
      @reports = report_source.ordered.
        for_list.
        limit(50)
    end

    def create
      @filter = ::Filters::Initiative.new(report_params)
      if @filter.valid?
        WarehouseReports::InitiativeReportJob.perform_later(@filter.options_for_initiative().as_json)
        redirect_to warehouse_reports_initiatives_path
      else
        render :index
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_initiatives_path)
    end

    def show
      @parameters = OpenStruct.new(@report.parameters.with_indifferent_access)
      @data = OpenStruct.new(@report.data.with_indifferent_access)
      @report_range = @parameters.start..@parameters.end
      @comparison_range = @parameters.comparison_start..@parameters.comparison_end
    end

    def set_report
      @report = report_source.find(params[:id].to_i)
    end

    def report_source
      GrdaWarehouse::WarehouseReports::InitiativeReport
    end

    def report_params
      params.require(:filter).permit(
        :initiative_name,
        :start, 
        :end,
        :comparison_start, 
        :comparison_end,
        :sub_population,
        project_ids: [],
        project_group_ids: [],
      )
    end

    # Override default to allow token access
    def report_visible?
      return true if access_by_token? || related_report.viewable_by(current_user).exists? 
      not_authorized!
    end

    def access_by_token?
      return false if current_user
      if params[:token].blank?
        raise ActionController::RoutingError.new('Not Found') and return
      end
      set_report
      if @report.updated_at > 3.months.ago && @report.token.present? && @report.token == params[:token]
        return true
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end

    def median array
      mid = array.size / 2
      sorted = array.sort
      array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2 
    end
    helper_method :median

    def show_view_partials
      [
        {partial: 'breakdown', data: :client_counts},
        {partial: 'nightly_census', title: 'Nightly Census'},
        {partial: 'breakdown', data: :gender_breakdowns},
        {partial: 'breakdown', data: :veteran_breakdowns, title: "Veteran Status Breakdowns"},
        {partial: 'breakdown', data: :ethnicity_breakdowns},
        {partial: 'breakdown', data: :race_breakdowns},
        {partial: 'breakdown', data: :age_breakdowns},
        {partial: 'breakdown', data: :length_of_stay_breakdowns},
        {partial: 'breakdown', data: :living_situation_breakdowns, title: "Living Situation Breakdowns"},
        {partial: 'income_pie_charts', data: :income_at_entry_breakdowns, title: "Income at Entry Breakdowns"},
        {partial: 'income_pie_charts', data: :income_most_recent_breakdowns, title: "Income Most Recent Breakdowns"},
        {partial: 'breakdown', data: :destination_breakdowns, title: "Destination Breakdowns"},
        {partial: 'zip_map', title: "Permanent Zipcode Breakdowns"}
      ]
    end
    helper_method :show_view_partials

    def flash_interpolation_options
      { resource_name: 'Initiative Report' }
    end
  end
end