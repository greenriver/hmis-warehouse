module WarehouseReports
  class HealthMemberStatusReportJob < ActiveJob::Base
    queue_as :high_priority

    attr_accessor :params, :report_start_date, :report_end_date, :report_id, :current_user_id

    def initialize params
      @report_start_date = params[:report_start_date]
      @report_end_date = params[:report_end_date]
      @report_id = params[:report_id]
      @current_user_id = params[:current_user_id]
    end

    def perform
      @report = report_source.find(report_id)
      @report.run!
      NotifyUser.health_member_status_report_finished(@current_user_id).deliver_later
    end

    def enqueue(job, queue: :low_priority)
    end

    def max_attempts
      1
    end

    def error(job, exception)
      @report = report_source.find(report_id)
      @report.update(error: "Failed: #{exception.message}")
    end

    def report_source
      Health::MemberStatusReport
    end

  end
end