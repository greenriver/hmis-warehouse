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

    def arel
      Hmis::ArelHelper.instance
    end

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

    def heads_of_household_for(scope)
      heads_of_household_scope_for(scope).as_report_members
    end

    def heads_of_household_scope_for(scope)
      return report_enrollment_universe.none if scope.blank?

      household_ids = if scope.try(:model) == HopwaCaper::Enrollment
        scope.select(:report_household_id)
      else
        scope
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
