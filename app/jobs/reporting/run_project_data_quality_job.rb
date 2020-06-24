###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting
  class RunProjectDataQualityJob < BaseJob
    queue_as :long_running

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
      @report.notify_requestor
      @report.send_notifications if @send_email
    end
  end
end
