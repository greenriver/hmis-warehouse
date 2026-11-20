###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class DisabilitiesController < ApplicationController
    include WarehouseReportAuthorization
    include WarehouseReports::QueuedReportJobs

    before_action :set_jobs, only: [:index, :running]
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.ordered.limit(50)

      # Set default filter to prior run
      options = if filter_params.present?
        filter_params[:filter]
      else
        @reports&.last&.parameters.try(:[], 'filter')&.with_indifferent_access
      end
      @filter = ::Filters::DisabilitiesReportFilter.new(options)
    end

    def create
      @filter = ::Filters::DisabilitiesReportFilter.new(filter_params)
      @filter.valid?
      @report = report_source.new(parameters: filter_params)
      if @report.valid?
        WarehouseReports::RunEnrolledDisabledJob.perform_later({ filter: filter_params }.merge(current_user_id: current_user.id))
      else
        flash[:error] = @report.errors.messages.values.join('<br />').html_safe
      end
      redirect_to(warehouse_reports_disabilities_path)
    end

    def show
      @clients = @report.data
      current_user.policy_context.preload_client_dependencies(@clients.map { |client| client['id'] })

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
      @reports = report_scope.ordered.limit(50)
    end

    def set_jobs
      @job_reports = queued_reports('RunEnrolledDisabledJob')
    end

    def set_report
      @report = report_scope.find params[:id].to_i
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

    private def report_scope
      report_source.visible_to(current_user)
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
      ::HudHelper.util.disability_types.invert.except(*exclude)
    end
    helper_method :available_disabilities

    # A stored run carries the labels its runner could see, but other users can open it,
    # so filter sensitive labels by the viewer's permissions. The row's PII policy covers
    # client restriction and the detail-download PII setting; it doesn't check the viewer's
    # HIV permission when there's no project, so check that too.
    def visible_disabilities(client, policy:)
      hud_util = ::HudHelper.util
      hidden = []
      hiv_hidden = !can_view_hiv_status? || !policy.can_view_hiv_status?
      hidden << hud_util.disability_type(8, raise_on_missing: true) if hiv_hidden
      hidden << hud_util.disability_type(9, raise_on_missing: true) unless can_view_dmh_status?

      client['disabilities'] - hidden
    end
    helper_method :visible_disabilities

    def available_project_types
      ::HudHelper.util.project_types.invert
    end
    helper_method :available_project_types

    def flash_interpolation_options
      { resource_name: 'Enrolled Clients with Disabilities Report' }
    end
  end
end
