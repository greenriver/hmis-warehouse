module Reporting
  class RunProjectDataQualityJob < ActiveJob::Base
    attr_accessor :report_id
    attr_accessor :generate
    attr_accessor :send_email
    def initialize report_id:, generate:, send_email:
      @report_id = report_id.to_i
      @generate = generate
      @send_email = send_email
    end

    # Only try once, if we try again it erases previous failures since it doesn't bother to try since the previous run
    # is partially complete
    def max_attempts
      1 
    end

    def perform
      @report = GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.find(@report_id)
      if @generate
        @report.run!
      end
      if @send_email
        @report.send_notifications
      end
    end

  end
end