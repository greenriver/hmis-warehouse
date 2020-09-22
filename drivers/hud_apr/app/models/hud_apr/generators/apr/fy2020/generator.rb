###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class Generator < HudReports::GeneratorBase
    def initialize(options)
      super(options)
    end

    def self.title
      'Annual Performance Report - FY 2020'
    end

    def self.questions
      [
        HudApr::Generators::Shared::Fy2020::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::Shared::Fy2020::QuestionFive, # Report Validations Table
        HudApr::Generators::Shared::Fy2020::QuestionSix, # Data Quality
        HudApr::Generators::Apr::Fy2020::QuestionSeven, # Persons Served
        HudApr::Generators::Shared::Fy2020::QuestionEight, # Households Served
        HudApr::Generators::Shared::Fy2020::QuestionEleven, # Age-Household Breakdown
        HudApr::Generators::Shared::Fy2020::QuestionTwelve, # Race & Ethnicity
        HudApr::Generators::Shared::Fy2020::QuestionThirteen, # Health
        HudApr::Generators::Shared::Fy2020::QuestionFourteen, # Domestic Violence
        HudApr::Generators::Shared::Fy2020::QuestionFifteen, # Living Situation
        HudApr::Generators::Shared::Fy2020::QuestionSixteen, #  Cash Income - Ranges
        HudApr::Generators::Shared::Fy2020::QuestionSeventeen, # Cash Income - Sources
        HudApr::Generators::Apr::Fy2020::QuestionEighteen, # Client Cash Income Category - Earned/Other Income Category - by Start and t/Exit Status
        HudApr::Generators::Apr::Fy2020::QuestionNineteen, # Cash Income – Changes over Time
        HudApr::Generators::Shared::Fy2020::QuestionTwenty, # Non-Cash Benefits
        HudApr::Generators::Shared::Fy2020::QuestionTwentyOne, # Health Insurance
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end
  end
end
