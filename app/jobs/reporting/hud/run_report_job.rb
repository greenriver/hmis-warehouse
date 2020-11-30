###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting::Hud
  class RunReportJob < BaseJob
    def perform(class_name, report_id, email: true)
      report = HudReports::ReportInstance.find(report_id)
      report.start_report

      raise 'Unknown HUD Report class' unless Rails.application.config.hud_reports[class_name].present?

      @generator = class_name.constantize.new(report)
      @generator.class.questions.each do |q, klass|
        klass.new(@generator, report).run! if report.build_for_questions.include?(q)
      end

      report.complete_report
      NotifyUser.driver_hud_report_finished(@generator).deliver_now if report.user_id && email
    end
  end
end
