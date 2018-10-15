module WarehouseReports
  class HealthQualifyingActivitiesPayabilityJob < BaseJob
    queue_as :high_priority

    attr_accessor :params, :max_date, :report_id, :current_user_id

    def initialize params
      @max_date = params[:max_date]
      @report_id = params[:report_id]
      @current_user_id = params[:current_user_id]
    end

    def perform
      @report = report_source.find(report_id)
      @report.pre_calculate_qualifying_activity_payability!
      NotifyUser.health_qa_pre_calculation_finished(@current_user_id).deliver_later
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
      ::Health::Claim
    end

  end
end