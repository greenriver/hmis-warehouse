###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2022'
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

    def self.default_project_type_codes
      GrdaWarehouse::Hud::Project::PATH_PROJECT_TYPE_CODES
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
      questions.keys.detect { |q| q == question_number } || 'Q8-Q16'
    end

    def self.filter_class
      ::HudPathReport::Filters::PathFilter
    end

    def self.allowed_options
      [
        :start,
        :end,
        :coc_codes,
        :project_ids,
        :data_source_ids,
        :project_type_codes,
        :project_group_ids,
      ]
    end
  end
end
