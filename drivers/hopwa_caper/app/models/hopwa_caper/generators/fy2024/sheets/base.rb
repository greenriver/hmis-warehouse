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
      # @filter = HopwaCaper::Filters::HopwaCaperFilter.new(user_id: report.user_id).set_from_params(options)
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

    def report_client_universe
      HopwaCaper::Client
    end

    def report_enrollment_universe
      HopwaCaper::Enrollment
    end

    def add_two_col_header(sheet, label: 'Question')
      sheet.add_header(col: 'A', label: label)
      sheet.add_header(col: 'B', label: 'This Report')
    end
  end
end
