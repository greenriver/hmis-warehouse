module Reporting
  class DashboardExportJob < ActiveJob::Base
    attr_accessor :coc_code
    attr_accessor :report_id

    queue_as :high_priority
    
    def initialize coc_code:, report_id: 
      @coc_code = coc_code
      @report_id = report_id
    end

    # # Only try once, if we try again it erases previous failures since it doesn't bother to try since the previous run
    # # is partially complete
    # def max_attempts
    #   1 
    # end
    
    def perform
      # Find the associated report generator
      if @coc_code.present?
        Exporters::Tableau.export_all(coc_code: @coc_code, report_id: @report_id)
      else
        Exporters::Tableau.export_all(report_id: @report_id)
      end
    end

    def enqueue(job)

    end

    # def error(job, exception)
    #   result =  ReportResult.find(YAML.load(job.handler).result_id.to_i)
    #   result.update(job_status: "Failed: #{exception.message}")
    # end
  end
end
