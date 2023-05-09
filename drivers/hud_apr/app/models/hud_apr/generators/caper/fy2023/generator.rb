###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2023
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern

    def self.fiscal_year
      'FY 2023'
    end

    def self.generic_title
      'Consolidated Annual Performance and Evaluation Report'
    end

    def self.short_name
      'CAPER'
    end

    def self.default_project_type_codes
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.keys + [:prevention]
    end

    def url
      hud_reports_caper_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::Caper::Fy2023::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::Caper::Fy2023::QuestionFive, # Report Validations Table
        HudApr::Generators::Caper::Fy2023::QuestionSix, # Data Quality
        HudApr::Generators::Caper::Fy2023::QuestionSeven, # Persons Served
        HudApr::Generators::Caper::Fy2023::QuestionEight, # Households Served
        HudApr::Generators::Caper::Fy2023::QuestionNine, # Contacts and Engagements
        HudApr::Generators::Caper::Fy2023::QuestionTen, # Gender
        HudApr::Generators::Caper::Fy2023::QuestionEleven, # Age-Household Breakdown
        HudApr::Generators::Caper::Fy2023::QuestionTwelve, # Race & Ethnicity
        HudApr::Generators::Caper::Fy2023::QuestionThirteen, # Health
        HudApr::Generators::Caper::Fy2023::QuestionFourteen, # Domestic Violence
        HudApr::Generators::Caper::Fy2023::QuestionFifteen, # Living Situation
        HudApr::Generators::Caper::Fy2023::QuestionSixteen, #  Cash Income - Ranges
        HudApr::Generators::Caper::Fy2023::QuestionSeventeen, # Cash Income - Sources
        # No 18 for Caper
        HudApr::Generators::Caper::Fy2023::QuestionNineteen, # Cash Income - Changes over Time
        HudApr::Generators::Caper::Fy2023::QuestionTwenty, # Non-Cash Benefits
        HudApr::Generators::Caper::Fy2023::QuestionTwentyOne, # Health Insurance
        HudApr::Generators::Caper::Fy2023::QuestionTwentyTwo, # Length of participation
        HudApr::Generators::Caper::Fy2023::QuestionTwentyThree, # Destination
        HudApr::Generators::Caper::Fy2023::QuestionTwentyFour, # Homeless Prevention
        HudApr::Generators::Caper::Fy2023::QuestionTwentyFive, # Veterans
        HudApr::Generators::Caper::Fy2023::QuestionTwentySix, # Chronically Homeless
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
