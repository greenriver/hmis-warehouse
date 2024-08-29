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

    def relevant_enrollments(enrollment_filter: relevant_enrollments_filter, service_filter: relevant_services_filter)
      service_scope = service_filter.apply(HopwaCaper::Service.where(date_provided: @report.start_date...@report.end_date))
      enrollments = enrollment_filter.apply(@report.hopwa_caper_enrollments)
      enrollments.
        overlapping_range(start_date: @report.start_date, end_date: @report.end_date).
        joins(:services).
        merge(service_scope)
    end

    def relevant_services(enrollment_filter: relevant_enrollments_filter, service_filter: relevant_services_filter, start_date: @report.start_date)
      enrollment_scope = enrollment_filter.apply(HopwaCaper::Enrollment.overlapping_range(start_date: start_date, end_date: @report.end_date))
      service_scope = @report.hopwa_caper_services.
        where(date_provided: start_date...@report.end_date).
        joins(:enrollment).merge(enrollment_scope)
      service_filter.apply(service_scope)
    end
  end
end
