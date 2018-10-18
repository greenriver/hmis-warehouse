module WarehouseReports
  class DisabilitiesController < ApplicationController
    include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]

    def index
      @filter = DisabilityProjectTypeFilter.new(filter_params)

      if params[:commit].present?
        WarehouseReports::RunEnrolledDisabledJob.perform_later(params.merge(current_user_id: current_user.id))
      end
      @reports = report_source.ordered.limit(50)
    end

    def show
      @report = report_source.find params[:id]
      @clients = @report.data

      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Enrolled Clients with Disabilities.xlsx"
        end
      end
    end

    def destroy
      @report = report_source.find params[:id].to_i
      @report.destroy
      respond_with(@report, location: warehouse_reports_disabilities_path)
    end

    def running
      @reports = report_source.ordered.limit(50)
    end

    def set_jobs
      @jobs = Delayed::Job.where(queue: 'enrolled_disabled_report').order(run_at: :desc)
    end

    def filter_params
      filter_params = begin
        f_params = params.require(:filter).permit(
          disabilities: [],
          project_types: [],
        )
        if f_params[:disabilities].present?
          f_params[:disabilities] = f_params[:disabilities].select{|m| available_disabilities.values.include?(m.to_i)}
        end
        f_params
      rescue
        {}
      end
    end

    def report_source
      GrdaWarehouse::WarehouseReports::EnrolledDisabledReport
    end

    def available_disabilities
      exclude = []
      exclude << 'HIV/AIDS' unless can_view_hiv_status?
      exclude << 'Mental health problem' unless can_view_dmh_status?
      ::HUD.disability_types.invert.except(*exclude)
    end
    helper_method :available_disabilities

    def available_project_types
      ::HUD.project_types.invert
    end
    helper_method :available_project_types

    class DisabilityProjectTypeFilter < ModelForm
      attribute :disabilities, Array, lazy: true, default: []
      attribute :project_types, Array, lazy: true, default: []
    end

    def flash_interpolation_options
      { resource_name: 'Enrolled Clients with Disabilities Report' }
    end
  end
end
