###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class Base < ::HudReports::QuestionBase
    def initialize(generator = nil, report = nil, options: {})
      super
      report.options.with_indifferent_access.merge(user_id: report.user_id) if options.blank?
    end

    protected

    def question_sheet(question:)
      sheet = HudReports::QuestionSheet.new(report: @report, question: question)
      if block_given?
        builder = sheet.builder
        yield(builder)
        sheet.build(builder)
      end
      sheet
    end

    def report_enrollment_universe
      HopwaCaper::Enrollment
    end

    def overlapping_enrollments(scope)
      scope.overlapping_range(start_date: @report.start_date, end_date: @report.end_date)
    end
  end
end
