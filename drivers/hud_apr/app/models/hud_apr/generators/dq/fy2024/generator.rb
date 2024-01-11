###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern
    def self.fiscal_year
      'FY 2024'
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
      HudUtility2024.residential_project_type_numbers_by_code.keys
    end

    def url
      hud_reports_dq_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::Dq::Fy2024::QuestionOne,
        HudApr::Generators::Dq::Fy2024::QuestionTwo,
        HudApr::Generators::Dq::Fy2024::QuestionThree,
        HudApr::Generators::Dq::Fy2024::QuestionFour,
        HudApr::Generators::Dq::Fy2024::QuestionFive,
        HudApr::Generators::Dq::Fy2024::QuestionSix,
        HudApr::Generators::Dq::Fy2024::QuestionSeven,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 1'
    end
  end
end
