module Reporting
  class RunReportJob < ActiveJob::Base
    attr_accessor :result_id
    attr_accessor :report
    def initialize report:, result_id:, options:
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
        report_generator = @report.class.name.gsub('Reports::', 'ReportGenerators::').constantize.new(@options).run!
      else
        report_generator = @report.class.name.gsub('Reports::', 'ReportGenerators::').constantize.new.run!
      end
    end

    def enqueue(job)

    end

    def error(job, exception)
      result =  ReportResult.find(YAML.load(job.handler).result_id.to_i)
      result.update(job_status: "Failed: #{exception.message}")
    end
  end
end