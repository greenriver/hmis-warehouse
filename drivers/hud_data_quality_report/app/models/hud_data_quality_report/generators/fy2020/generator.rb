###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2020'
    end

    def self.generic_title
      'Data Quality Report'
    end

    def self.short_name
      'DQ'.freeze
    end

    def url
      hud_reports_dq_url(report, { host: ENV['FQDN'], protocol: 'https' })
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
  end
end
