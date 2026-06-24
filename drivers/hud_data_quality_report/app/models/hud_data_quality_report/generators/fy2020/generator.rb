###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport::Generators::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2020'
    end

    def self.generic_title
      'Data Quality Report'
    end

    def self.short_name
      'DQ'
    end

    def url
      hud_reports_past_dq_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudDataQualityReport::Generators::Fy2020::QuestionOne,
        HudDataQualityReport::Generators::Fy2020::QuestionTwo,
        HudDataQualityReport::Generators::Fy2020::QuestionThree,
        HudDataQualityReport::Generators::Fy2020::QuestionFour,
        HudDataQualityReport::Generators::Fy2020::QuestionFive,
        HudDataQualityReport::Generators::Fy2020::QuestionSix,
        HudDataQualityReport::Generators::Fy2020::QuestionSeven,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 1'
    end

    # HudReportArchival.register_archival_generator(self.title, self) runs when this
    # concern is included. Include at the end of the class to ensure all required fields
    # are loaded for registration
    include HudDataQualityReport::Archival
  end
end
