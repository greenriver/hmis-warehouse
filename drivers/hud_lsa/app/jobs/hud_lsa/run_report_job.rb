###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa
  class RunReportJob < ::BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(report_id, email: true)
      report = HudLsa::Generators::Fy2022::Lsa.find(report_id)
      report.start_report
      report.run!
      report.complete_report
      # make the emailer work
      report.report = report
      NotifyUser.driver_hud_report_finished(report).deliver_now if report.user_id && email
    end
  end
end
