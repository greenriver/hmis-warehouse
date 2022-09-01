###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern

    def self.fiscal_year
      'FY 2022'
    end

    def self.generic_title
      'Consolidated Annual Performance and Evaluation Report'
    end

    def self.short_name
      'CAPER'
    end

    def self.default_project_type_codes
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.keys
    end

    def url
      hud_reports_caper_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::Caper::Fy2021::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::Caper::Fy2021::QuestionFive, # Report Validations Table
        HudApr::Generators::Caper::Fy2021::QuestionSix, # Data Quality
        HudApr::Generators::Caper::Fy2021::QuestionSeven, # Persons Served
        HudApr::Generators::Caper::Fy2021::QuestionEight, # Households Served
        HudApr::Generators::Caper::Fy2021::QuestionNine, # Contacts and Engagements
        HudApr::Generators::Caper::Fy2021::QuestionTen, # Gender
        HudApr::Generators::Caper::Fy2021::QuestionEleven, # Age-Household Breakdown
        HudApr::Generators::Caper::Fy2021::QuestionTwelve, # Race & Ethnicity
        HudApr::Generators::Caper::Fy2021::QuestionThirteen, # Health
        HudApr::Generators::Caper::Fy2021::QuestionFourteen, # Domestic Violence
        HudApr::Generators::Caper::Fy2021::QuestionFifteen, # Living Situation
        HudApr::Generators::Caper::Fy2021::QuestionSixteen, #  Cash Income - Ranges
        HudApr::Generators::Caper::Fy2021::QuestionSeventeen, # Cash Income - Sources
        # No 18 for Caper
        HudApr::Generators::Caper::Fy2021::QuestionNineteen, # Cash Income - Changes over Time
        HudApr::Generators::Caper::Fy2021::QuestionTwenty, # Non-Cash Benefits
        HudApr::Generators::Caper::Fy2021::QuestionTwentyOne, # Health Insurance
        HudApr::Generators::Caper::Fy2021::QuestionTwentyTwo, # Length of participation
        HudApr::Generators::Caper::Fy2021::QuestionTwentyThree, # Destination
        HudApr::Generators::Caper::Fy2021::QuestionTwentyFour, # Homeless Prevention
        HudApr::Generators::Caper::Fy2021::QuestionTwentyFive, # Veterans
        HudApr::Generators::Caper::Fy2021::QuestionTwentySix, # Chronically Homeless
        # No 27 for Caper
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end
  end
end
