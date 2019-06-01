###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting
  class RunProjectDataQualityJob < BaseJob
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
      @report.notify_requestor
      if @send_email
        @report.send_notifications
      end
    end

  end
end
