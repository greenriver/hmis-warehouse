###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2022
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2022'
    end

    def self.generic_title
      'Data Quality Report'
    end

    def self.short_name
      'DQ'.freeze
    end

    def self.default_project_type_codes
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.keys
    end

    def url
      hud_reports_dq_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudDataQualityReport::Generators::Fy2022::QuestionOne,
        HudDataQualityReport::Generators::Fy2022::QuestionTwo,
        HudDataQualityReport::Generators::Fy2022::QuestionThree,
        HudDataQualityReport::Generators::Fy2022::QuestionFour,
        HudDataQualityReport::Generators::Fy2022::QuestionFive,
        HudDataQualityReport::Generators::Fy2022::QuestionSix,
        HudDataQualityReport::Generators::Fy2022::QuestionSeven,
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
  end
end
