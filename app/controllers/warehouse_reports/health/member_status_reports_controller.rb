module WarehouseReports::Health
  class MemberStatusReportsController < ApplicationController
    before_action :require_can_view_member_health_reports!

    helper HealthOverviewHelper

    def index
      if params[:report].present?
        options = report_params
      else
        options = default_options
      end
      @report = OpenStruct.new(options)
      @reports = report_scope.page(params[:page]).per(20)
    end

    def show
      # CP Member Status and Outreach File: “CP_[CP Short Name]_MH_STATUSOUTREACH_FULL_YYYYMMDD.XLSX”
      # i. Example: CP_BHCHP-CP_STATUSOUTREACH_FULL_20180718.XLSX
      #
      # Summary File: Files sent by ACO, MCO, or CP: “[ACO, MCO or CP]_[ACO, MCO or CP Short Name]_MH_SUMMARY_FULL_YYYYMMDD.XLSX”
      # iii. Example: CP_BHCHP-CP_MH_SUMMARY_FULL_20180718.XLSX
    end

    def create
      @report = Health::MemberStatusReport.create(report_params.merge(user_id: current_user.id))
      job = Delayed::Job.enqueue(
        ::WarehouseReports::HealthMemberStatusReportJob.new(
          report_params.merge(
            report_id: @report.id, current_user_id: current_user.id
          )
        ),
        queue: :low_priority
      )
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_health_member_status_reports_path
    end

    def destroy

    end

    def default_options
      {
        report_start_date: 1.months.ago.to_date,
        report_end_date: 1.days.ago.to_date,
      }
    end

    def report_params
      params.require(:report).permit(
        :report_start_date,
        :report_end_date,
        :receiver
      )
    end

    def report_source
      Health::MemberStatusReport
    end

    def report_scope
      report_source.visible_by?(current_user)
    end

    def flash_interpolation_options
      { resource_name: 'Report' }
    end
  end
end