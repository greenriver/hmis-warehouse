module Reporting::Hud::Ahar::Fy2017
  class RunReportJob < BaseJob
    queue_as :high_priority

    def initialize report_id:, result_id:, options:
      @report_id = report_id
      @result_id = result_id
      @options = options
    end

    # Only try once, if we try again it erases previous failures since it doesn't bother to try since the previous run
    # is partially complete
    def max_attempts
      1
    end

    def perform
      report = Report.find(@report_id)
      report_generator = report.class.generator
      report_generator.new(@options).run!
    end

    def enqueue(job)

    end

    def error(job, exception)
      result =  ReportResult.find(@result_id)
      result.update(job_status: "Failed: #{exception.message}")
    end
  end
end