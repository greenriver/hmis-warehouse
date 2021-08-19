###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class DisabilitiesController < ApplicationController
    include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]
    before_action :set_report, only: [:show, :destroy]

    def index
      @filter = ::Filters::DisabilitiesReportFilter.new(filter_params)
      @reports = report_source.ordered.limit(50)
    end

    def create
      @filter = ::Filters::DisabilitiesReportFilter.new(filter_params)
      @filter.valid?
      @report = report_source.new(parameters: filter_params)
      if @report.valid?
        WarehouseReports::RunEnrolledDisabledJob.perform_later({ filter: job_params }.merge(current_user_id: current_user.id))
      else
        flash[:error] = @report.errors.messages.values.join('<br />').html_safe
      end
      redirect_to(warehouse_reports_disabilities_path)
    end

    def show
      @clients = @report.data

      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = 'attachment; filename=Enrolled Clients with Disabilities.xlsx'
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_disabilities_path)
    end

    def yes_no(bool)
      return 'unknown' if bool.nil?

      bool ? 'yes' : 'no'
    end
    helper_method :yes_no

    def running
      @reports = report_source.ordered.limit(50)
    end

    def set_jobs
      @jobs = Delayed::Job.jobs_for_class('RunEnrolledDisabledJob').order(run_at: :desc)
    end

    def set_report
      @report = report_source.find params[:id].to_i
    end

    def job_params
      params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :heads_of_household,
        age_ranges: [],
        disabilities: [],
        project_types: [],
      )
    end

    def filter_params
      f_params = params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :heads_of_household,
        age_ranges: [],
        disabilities: [],
        project_types: [],
      )
      f_params[:disabilities] = f_params[:disabilities].select { |m| available_disabilities.value?(m.to_i) }.reject(&:blank?) if f_params[:disabilities].present?
      f_params[:project_types] = f_params[:project_types].reject(&:blank?)
      f_params[:age_ranges] = f_params[:age_ranges].reject(&:blank?)
      f_params
    rescue StandardError
      {}
    end

    def report_source
      GrdaWarehouse::WarehouseReports::EnrolledDisabledReport
    end

    def available_sub_populations
      AvailableSubPopulations.available_sub_populations
      # {
      #   'All Clients' => :all_clients,
      #   'Youth' => :youth,
      #   'Veterans' => :veteran,
      # }
    end
    helper_method :available_sub_populations

    def available_disabilities
      exclude = []
      exclude << 'HIV/AIDS' unless can_view_hiv_status?
      exclude << 'Mental health disorder' unless can_view_dmh_status?
      ::HUD.disability_types.invert.except(*exclude)
    end
    helper_method :available_disabilities

    def available_project_types
      ::HUD.project_types.invert
    end
    helper_method :available_project_types

    def flash_interpolation_options
      { resource_name: 'Enrolled Clients with Disabilities Report' }
    end
  end
end
