###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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
      if klass
        report = klass.find(report_id)
        report.run_and_save!

        NotifyUser.report_completed(user_id, report).deliver_later
      else
        setup_notifier('Generic Report Runner')
        msg = "Unable to run report, #{report_class} is not included in the white list."
        @notifier.ping(msg) if @send_notifications
      end
    end

    def whitelisted_reports
      {
        'GrdaWarehouse::WarehouseReports::Youth::Export' => ::GrdaWarehouse::WarehouseReports::Youth::Export,
        'Health::SsmExport' => ::Health::SsmExport,
        'Health::EncounterReport' => ::Health::EncounterReport,
      }
    end
  end
end
