module WarehouseReports
  class DisabilitiesController < ApplicationController
    include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]

    def index
      @filter = DisabilityProjectTypeFilter.new(filter_params)
      if params[:commit].present?
        WarehouseReports::RunEnrolledDisabledJob.perform_later(params.merge(current_user_id: current_user.id))
      end
      @reports = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.ordered.limit(50)
    end

    def show
      @report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.find params[:id]
      @clients = @report.data

      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Enrolled Clients with Disabilities.xlsx"
        end
      end
    end

    def destroy
      @report = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.find params[:id]
      @report.destroy
      respond_with(@report, location: warehouse_reports_disabilities_path)
    end

    def running
      @reports = GrdaWarehouse::WarehouseReports::EnrolledDisabledReport.ordered.limit(50)
    end

    def set_jobs
      @jobs = Delayed::Job.where(queue: 'enrolled_disabled_report').order(run_at: :desc)
    end

    def filter_params
      filter_params = params.require(:filter).permit(
        disabilities: [],
        project_types: [],
      ) rescue {}
    end

    def available_disabilities
      ::HUD.disability_types.invert
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
  end
end
