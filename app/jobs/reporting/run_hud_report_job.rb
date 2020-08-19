###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting
  class RunHudReportJob < BaseJob
    def perform(class_name, questions, report_id)
      report = HudReports::ReportInstance.find(report_id)
      report.update(state: 'Started', started_at: Time.current)

      @generator = class_name.constantize.new(report.options)
      @generator.class.questions.each do |name, clazz|
        clazz.new(@generator, report).run! unless questions.present? && questions.exclude?(name)
      end

      report.update(state: 'Completed', completed_at: Time.current)
    end
  end
end
