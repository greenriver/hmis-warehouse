###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.title
      'Consolidated Annual Performance and Evaluation Report - FY 2020'
    end

    def self.short_name
      'CAPER'
    end

    def url
      hud_reports_caper_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      HudApr::Filters::AprFilter
    end

    def self.questions
      [
        HudApr::Generators::Caper::Fy2020::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::Caper::Fy2020::QuestionFive, # Report Validations Table
        HudApr::Generators::Caper::Fy2020::QuestionSix, # Data Quality
        HudApr::Generators::Caper::Fy2020::QuestionSeven, # Persons Served
        HudApr::Generators::Caper::Fy2020::QuestionEight, # Households Served
        HudApr::Generators::Caper::Fy2020::QuestionNine, # Contacts and Engagements
        HudApr::Generators::Caper::Fy2020::QuestionTen, # Gender
        HudApr::Generators::Caper::Fy2020::QuestionEleven, # Age-Household Breakdown
        HudApr::Generators::Caper::Fy2020::QuestionTwelve, # Race & Ethnicity
        HudApr::Generators::Caper::Fy2020::QuestionThirteen, # Health
        HudApr::Generators::Caper::Fy2020::QuestionFourteen, # Domestic Violence
        HudApr::Generators::Caper::Fy2020::QuestionFifteen, # Living Situation
        HudApr::Generators::Caper::Fy2020::QuestionSixteen, #  Cash Income - Ranges
        HudApr::Generators::Caper::Fy2020::QuestionSeventeen, # Cash Income - Sources
        # No 18 for Caper
        HudApr::Generators::Caper::Fy2020::QuestionNineteen, # Cash Income – Changes over Time
        HudApr::Generators::Caper::Fy2020::QuestionTwenty, # Non-Cash Benefits
        HudApr::Generators::Caper::Fy2020::QuestionTwentyOne, # Health Insurance
        HudApr::Generators::Caper::Fy2020::QuestionTwentyTwo, # Length of participation
        HudApr::Generators::Caper::Fy2020::QuestionTwentyThree, # Destination
        HudApr::Generators::Caper::Fy2020::QuestionTwentyFour, # Homeless Prevention
        HudApr::Generators::Caper::Fy2020::QuestionTwentyFive, # Veterans
        HudApr::Generators::Caper::Fy2020::QuestionTwentySix, # Chronically Homeless
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
