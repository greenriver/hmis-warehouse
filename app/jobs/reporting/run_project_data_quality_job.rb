module Reporting
  class RunProjectDataQualityJob < ActiveJob::Base
    queue_as :high_priority

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

  end
end