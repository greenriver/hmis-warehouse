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
      {
        'Question 4' => HudApr::Generators::Shared::Fy2020::QuestionFour, # Project Identifiers in HMIS
        'Question 5' => HudApr::Generators::Shared::Fy2020::QuestionFive, # Report Validations Table
        'Question 6' => HudApr::Generators::Shared::Fy2020::QuestionSix, # Data Quality
        'Question 7' => HudApr::Generators::Apr::Fy2020::QuestionSeven, # Persons Served
        'Question 8' => HudApr::Generators::Shared::Fy2020::QuestionEight, # Households Served

        'Question 11' => HudApr::Generators::Shared::Fy2020::QuestionEleven, # Age-Household Breakdown
      }.freeze
    end
  end
end
