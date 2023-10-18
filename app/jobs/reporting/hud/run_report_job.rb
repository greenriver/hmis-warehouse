###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::Hud
  class RunReportJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(class_name, report_id, email: true)
      raise "Unknown HUD Report class: #{class_name}" unless Rails.application.config.hud_reports[class_name].present?

      report = HudReports::ReportInstance.find_by(id: report_id)
      # Occassionally people delete the report before it actually runs
      return unless report.present?

      report.start_report
      @generator = class_name.constantize.new(report)
      @generator.class.questions.each do |q, klass|
        next unless report.build_for_questions.include?(q)

        klass.new(@generator, report).run!
      end

      report.complete_report
      NotifyUser.driver_hud_report_finished(@generator).deliver_now if report.user_id && email
    end
  end
end
