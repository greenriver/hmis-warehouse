module Reporting
  class RunProjectDataQualityJob < ActiveJob::Base
    def perform(report_id:, generate:, send_email:)
      @report_id = report_id.to_i
      @generate = generate
      @send_email = send_email
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