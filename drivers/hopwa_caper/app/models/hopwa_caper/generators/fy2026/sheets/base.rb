# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
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

    def heads_of_household_for(enrollments_or_ids)
      heads_of_household_scope_for(enrollments_or_ids).as_report_members
    end

    def heads_of_household_scope_for(enrollments_or_ids)
      return report_enrollment_universe.none if enrollments_or_ids.blank?

      household_ids = if enrollments_or_ids.is_a?(ActiveRecord::Relation) && enrollments_or_ids.model == HopwaCaper::Enrollment
        enrollments_or_ids.select(:report_household_id)
      else
        enrollments_or_ids
      end

      @report.hopwa_caper_enrollments.
        head_of_household.
        where(report_household_id: household_ids).
        latest_by_distinct_client_id
    end

    def services_with_hoh(scope)
      scope.
        joins('JOIN hopwa_caper_enrollments hoh ON hopwa_caper_services.report_household_id = hoh.report_household_id AND hoh.relationship_to_hoh = 1')
    end
  end
end
