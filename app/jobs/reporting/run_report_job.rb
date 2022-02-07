###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class RunReportJob < BaseJob
    attr_accessor :result_id
    attr_accessor :report

    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def initialize(report:, result_id:, options:)
      @report = report
      @result_id = result_id
      @options = options
    end

    # Only try once, if we try again it erases previous failures since it doesn't bother to try since the previous run
    # is partially complete
    def max_attempts
      1
    end

    def perform
      # Find the associated report generator
      if @options.present?
        @report.class.name.gsub('Reports::', 'ReportGenerators::').constantize.new(@options).run!
      else
        @report.class.name.gsub('Reports::', 'ReportGenerators::').constantize.new.run!
      end

      user_id = ReportResult.where(id: @result_id).pluck(:user_id)&.first
      NotifyUser.hud_report_finished(user_id, @report.id, @result_id).deliver_later if user_id
    end

    def enqueue(job)
    end

    def error(job, exception)
      result = ReportResult.find(YAML.load(job.handler).result_id.to_i) # rubocop:disable Security/YAMLLoad
      result.update(job_status: "Failed: #{exception.message}")
      super(job, exception)
    end
  end
end
