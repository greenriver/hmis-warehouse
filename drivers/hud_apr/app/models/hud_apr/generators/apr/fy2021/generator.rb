###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern
    def self.fiscal_year
      'FY 2022'
    end

    def self.generic_title
      'Annual Performance Report'
    end

    def self.short_name
      'APR'
    end

    def url
      hud_reports_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      ::Filters::HudFilterBase
    end

    def self.questions
      [
        HudApr::Generators::Apr::Fy2021::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::Apr::Fy2021::QuestionFive, # Report Validations Table
        HudApr::Generators::Apr::Fy2021::QuestionSix, # Data Quality
        HudApr::Generators::Apr::Fy2021::QuestionSeven, # Persons Served
        HudApr::Generators::Apr::Fy2021::QuestionEight, # Households Served
        HudApr::Generators::Apr::Fy2021::QuestionNine, # Contacts and Engagements
        HudApr::Generators::Apr::Fy2021::QuestionTen, # Gender
        HudApr::Generators::Apr::Fy2021::QuestionEleven, # Age-Household Breakdown
        HudApr::Generators::Apr::Fy2021::QuestionTwelve, # Race & Ethnicity
        HudApr::Generators::Apr::Fy2021::QuestionThirteen, # Health
        HudApr::Generators::Apr::Fy2021::QuestionFourteen, # Domestic Violence
        HudApr::Generators::Apr::Fy2021::QuestionFifteen, # Living Situation
        HudApr::Generators::Apr::Fy2021::QuestionSixteen, #  Cash Income - Ranges
        HudApr::Generators::Apr::Fy2021::QuestionSeventeen, # Cash Income - Sources
        HudApr::Generators::Apr::Fy2021::QuestionEighteen, # Client Cash Income Category - Earned/Other Income Category - by Start and t/Exit Status
        HudApr::Generators::Apr::Fy2021::QuestionNineteen, # Cash Income – Changes over Time
        HudApr::Generators::Apr::Fy2021::QuestionTwenty, # Non-Cash Benefits
        HudApr::Generators::Apr::Fy2021::QuestionTwentyOne, # Health Insurance
        HudApr::Generators::Apr::Fy2021::QuestionTwentyTwo, # Length of participation
        HudApr::Generators::Apr::Fy2021::QuestionTwentyThree, # Destination
        HudApr::Generators::Apr::Fy2021::QuestionTwentyFive, # Veterans
        HudApr::Generators::Apr::Fy2021::QuestionTwentySix, # Chronically Homeless
        HudApr::Generators::Apr::Fy2021::QuestionTwentySeven, # Youth
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end
  end
end
