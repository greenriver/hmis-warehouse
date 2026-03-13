###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Dq::Fy2026
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern

    # When set, HouseholdContext records are copied from this report instead of being
    # recomputed. Used by the SPM, which runs DQ sub-reports and passes its own report ID
    # so that both reports share the same pre-computed household context.
    def source_report_id_for_contexts
      @source_report_id_for_contexts ||= report.options&.with_indifferent_access&.[](:source_report_id_for_contexts)
    end
    attr_writer :source_report_id_for_contexts

    def self.fiscal_year
      'FY 2026'
    end

    def self.generic_title
      'HMIS Data Quality Report'
    end

    def self.short_name
      'DQ'
    end

    def self.file_prefix
      "#{short_name} #{fiscal_year}"
    end

    def self.default_project_type_codes
      HudHelper.util('2026').residential_project_type_numbers_by_code.keys
    end

    def url
      hud_reports_dq_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def prepare_report
      super
      HudReports::HouseholdContextBuilder.call(self, report, enrollment_scope: base_enrollment_scope, source_report_id: source_report_id_for_contexts)
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::Dq::Fy2026::QuestionOne,
        HudApr::Generators::Dq::Fy2026::QuestionTwo,
        HudApr::Generators::Dq::Fy2026::QuestionThree,
        HudApr::Generators::Dq::Fy2026::QuestionFour,
        HudApr::Generators::Dq::Fy2026::QuestionFive,
        HudApr::Generators::Dq::Fy2026::QuestionSix,
        HudApr::Generators::Dq::Fy2026::QuestionSeven,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 1'
    end
  end
end
