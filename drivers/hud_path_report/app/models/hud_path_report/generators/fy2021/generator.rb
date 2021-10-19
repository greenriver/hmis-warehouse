###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2021'
    end

    def self.generic_title
      'Annual PATH Report'
    end

    def self.short_name
      'PATH'
    end

    def self.file_prefix
      "v3.5 #{short_name} #{fiscal_year}"
    end

    def url
      hud_reports_path_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudPathReport::Generators::Fy2021::QuestionEightToSixteen,
        HudPathReport::Generators::Fy2021::QuestionSeventeen,
        HudPathReport::Generators::Fy2021::QuestionEighteen,
        HudPathReport::Generators::Fy2021::QuestionNineteenToTwentyFour,
        HudPathReport::Generators::Fy2021::QuestionTwentyFive,
        HudPathReport::Generators::Fy2021::QuestionTwentySix,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 8 to 16'
    end

    def self.filter_class
      ::HudPathReport::Filters::PathFilter
    end
  end
end
