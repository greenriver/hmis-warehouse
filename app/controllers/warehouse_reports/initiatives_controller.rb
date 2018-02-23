module WarehouseReports
  class InitiativesController < ApplicationController
    include PjaxModalController
    include WarehouseReportAuthorization
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
      
    end

    def show
      @parameters = OpenStruct.new(@report.parameters.with_indifferent_access)
      @data = OpenStruct.new(@report.data.with_indifferent_access)
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

  end
end