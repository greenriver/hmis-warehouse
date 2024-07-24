###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class QualifyingActivitiesPayabilityJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    attr_accessor :params, :max_date, :report_id, :current_user_id, :test_file

    def initialize(params)
      @max_date = params[:max_date]
      @report_id = params[:report_id]
      @current_user_id = params[:current_user_id]
      @test_file = params[:test_file]
    end

    def perform
      @report = report_source.find(report_id)
      ::Health::Tasks::CalculateValidUnpayableQas.new.run!
      @report.pre_calculate_qualifying_activity_payability!
      @report.attach_associated_factories!
      NotifyUser.health_qa_pre_calculation_finished(@current_user_id).deliver_later
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
      ::Health::Claim
    end
  end
end
