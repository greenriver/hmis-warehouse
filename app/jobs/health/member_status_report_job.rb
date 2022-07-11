###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class MemberStatusReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    attr_accessor :params, :report_start_date, :report_end_date, :report_id, :current_user_id

    def initialize(params)
      @report_start_date = params[:report_start_date]
      @report_end_date = params[:report_end_date]
      @report_id = params[:report_id]
      @current_user_id = params[:current_user_id]
    end

    def perform
      @report = report_source.find(report_id)
      @report.run!
      NotifyUser.health_member_status_report_finished(@current_user_id).deliver_later(priority: -5)
    end

    def enqueue(job, queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running))
    end

    def max_attempts
      1
    end

    def error(job, exception)
      @report = report_source.find(report_id)
      @report.update(error: "Failed: #{exception.message}")
      super(job, exception)
    end

    def report_source
      ::Health::MemberStatusReport
    end
  end
end
