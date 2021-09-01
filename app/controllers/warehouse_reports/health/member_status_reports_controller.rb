###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class MemberStatusReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!
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
      # CP Member Status and Outreach File: "CP_[CP Short Name]_MH_STATUSOUTREACH_FULL_YYYYMMDD.XLSX"
      # i. Example: CP_BHCHP-CP_STATUSOUTREACH_FULL_20180718.XLSX
      #
      # Summary File: Files sent by ACO, MCO, or CP: "[ACO, MCO or CP]_[ACO, MCO or CP Short Name]_MH_SUMMARY_FULL_YYYYMMDD.XLSX"
      # iii. Example: CP_BHCHP-CP_MH_SUMMARY_FULL_20180718.XLSX

      @patients = @report.member_status_report_patients
      @sender = Health::Cp.sender.first
      respond_to do |format|
        format.xlsx do
          if params[:summary].present?
            response.headers['Content-Disposition'] = "attachment; filename=\"CP_#{@sender.short_name}_MH_SUMMARY_FULL_#{@report.effective_date.strftime('%Y%m%d')}.xlsx\""
          else
            response.headers['Content-Disposition'] = "attachment; filename=\"CP_#{@sender.short_name}_MH_STATUSOUTREACH_FULL_#{@report.effective_date.strftime('%Y%m%d')}.xlsx\""
          end
        end
      end
    end

    def create
      @report = Health::MemberStatusReport.create(report_params.merge(user_id: current_user.id))
      job = Delayed::Job.enqueue(
        ::Health::MemberStatusReportJob.new(
          report_params.merge(
            report_id: @report.id, current_user_id: current_user.id,
          ),
        ),
        queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running),
      )
      @report.update(job_id: job.id)
      respond_with @report, location: warehouse_reports_health_member_status_reports_path
    end

    def destroy
    end

    def set_reports
      @reports = report_scope.order(created_at: :desc).page(params[:page]).per(20)
    end

    def default_options
      {
        report_start_date: 1.months.ago.to_date,
        report_end_date: 1.days.ago.to_date,
        effective_date: Date.current,
      }
    end

    def report_params
      params.require(:report).permit(
        :report_start_date,
        :report_end_date,
        :effective_date,
        :receiver,
      )
    end

    def set_report
      @report = report_scope.find(params[:id].to_i)
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
