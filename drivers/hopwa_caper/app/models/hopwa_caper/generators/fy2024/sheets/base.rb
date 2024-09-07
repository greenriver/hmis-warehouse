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

    def add_two_col_header(sheet, label: 'Question')
      sheet.add_header(col: 'A', label: label)
      sheet.add_header(col: 'B', label: 'This Report')
    end

    # enrollments to report on in this sheet
    def relevant_enrollments(enrollment_filters: relevant_enrollments_filters, service_filters: relevant_services_filters)
      service_scope = service_filters.
        reduce(HopwaCaper::Service.all) { |scope, filter| filter.apply(scope) }.
        where(date_provided: @report.start_date...@report.end_date)

      enrollment_filters.
        reduce(@report.hopwa_caper_enrollments) { |scope, filter| filter.apply(scope) }.
        overlapping_range(start_date: @report.start_date, end_date: @report.end_date).
        joins(:services).
        merge(service_scope)
    end

    # services to report on in this sheet
    def relevant_services(enrollment_filters: relevant_enrollments_filters, service_filters: relevant_services_filters, start_date: @report.start_date)
      enrollment_scope = enrollment_filters.
        reduce(HopwaCaper::Enrollment.all) { |scope, filter| filter.apply(scope) }.
        overlapping_range(start_date: start_date, end_date: @report.end_date)

      service_filters.
        reduce(@report.hopwa_caper_services) { |scope, filter| filter.apply(scope) }.
        where(date_provided: start_date...@report.end_date).
        joins(:enrollment).merge(enrollment_scope)
    end
  end
end
