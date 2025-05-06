###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudLsa
  class RunReportJob < ::BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(report_id, email: true)
      # For whatever reason this gets run as an active job that isn't obeying the `max_attempts` method
      # Just set attempts to 2 now so we don't try again
      dj = Delayed::Job.jobs_for_class(job_id)&.first
      dj&.update(attempts: 2)
      report = HudLsa::Generators::Fy2024::Lsa.find(report_id)
      report.start_report
      report.run!
      report.complete_report
      # make the emailer work
      report.report = report

      report_name = if report.hic?
        'HIC'
      else
        'LSA'
      end
      report_url = report.url
      NotifyUser.driver_hud_report_finished(report, report_name: report_name, report_url: report_url).deliver_now if report.user_id && email
    end

    def max_attempts
      1
    end
  end
end
