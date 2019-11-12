###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class GenericReportJob < BaseJob
    include ArelHelper

    queue_as :high_priority

    # NOTE: instances of report_class must provide `title`, `url`, and `run_and_save!` methods
    # `title` should return a string suitable for an email subject
    # `run_and_save!` should run whatever calculations are necessary and save the results
    # `url` must provide a link to the individual report
    def perform(user_id:, report_class:, report_id:)
      klass = whitelisted_reports[report_class]
      return unless klass

      report = klass.find(report_id)
      report.run_and_save!

      NotifyUser.report_completed(user_id, report).deliver_later
    end

    def whitelisted_reports
      {
        'GrdaWarehouse::WarehouseReports::Youth::Export' => GrdaWarehouse::WarehouseReports::Youth::Export,
      }
    end
  end
end
