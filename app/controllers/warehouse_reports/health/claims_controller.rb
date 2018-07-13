module WarehouseReports::Health
  class ClaimsController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_reports, only: [:index, :running]
    before_action :set_report, only: [:show, :destroy]

    def index
      if params[:report].present?
        options = report_params
      else
        options = default_options
      end
      @report = OpenStruct.new(options)
    end

    def running
    end

    def show

    end

    def create
      @report = Health::Claim.create!(report_params.merge(user_id: current_user.id))
      job = Delayed::Job.enqueue(
        ::WarehouseReports::HealthClaimsJob.new(
          report_params.merge(
            report_id: @report.id, current_user_id: current_user.id
          )
        ),
        queue: :low_priority
      )
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_health_claims_path
    end

    def destroy

    end

    def set_reports
      @reports = report_scope.order(created_at: :desc).page(params[:page]).per(20)
    end

    def default_options
      {
        max_date: 1.days.ago.to_date,
      }
    end

    def report_params
      params.require(:report).permit(
        :max_date,
      )
    end

    def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    def report_source
      Health::Claim
    end

    def report_scope
      report_source.visible_by?(current_user)
    end

    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end