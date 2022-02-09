###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports::Ahar::Fy2017
  class BaseController < ApplicationController
    before_action :require_can_view_all_reports!

    def create
      @report = report_source.first
      options = report_params
      @result = report_result_source.create(
        report_id: @report.id,
        percent_complete: 0.0,
        user_id: current_user.id,
        options: options,
      )
      job = Delayed::Job.enqueue Reporting::Hud::Ahar::Fy2017::RunReportJob.new(
        report_id: @report.id,
        result_id: @result.id,
        options: options,
      ), queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
      @result.update(delayed_job_id: job.id)
      if @result.errors.full_messages.present?
        flash[:error] = @result.errors.full_messages.join(' ')
        redirect_to report_report_results_path(report_id: @report.id)
      else
        respond_with(@result, location: report_report_results_path(report_id: @report.id))
      end
    end

    def report_params
      params.require(:options).permit(
        *report_source.available_options,
      )
    end

    def report_source
      Reports::Ahar::Fy2017::Base
    end

    def report_result_source
      ReportResult
    end

    def flash_interpolation_options
      { resource_name: @report.name }
    end
  end
end
