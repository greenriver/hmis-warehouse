module Reporting
  class RunProjectDataQualityJob < ActiveJob::Base

    def perform(report_id:, generate:, send_email:)
      @report_id = report_id.to_i
      @generate = generate
      @send_email = send_email
      @report = GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.find(@report_id)
      if @generate
        begin
          @report.run!
        rescue Exception => e
          @report.update(processing_errors: [e.message, e.backtrace].to_json)
        end
      end
      if @send_email
        @report.send_notifications
      end
    end

    def enqueue(job, queue: :default_priority)
    end

  end
end