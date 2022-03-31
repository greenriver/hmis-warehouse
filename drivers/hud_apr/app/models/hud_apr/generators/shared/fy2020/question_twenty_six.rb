###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentySix < Base
    QUESTION_NUMBER = 'Question 26'.freeze

    def self.table_descriptions
      {
        'Question 26' => 'Chronic Homeless Questions',
        'Q26a' => 'Chronic Homeless Status - Number of Households w/at least one or more CH person',
        'Q26b' => 'Number of Chronically Homeless Persons by Household',
        'Q26c' => 'Gender of Chronically Homeless Persons',
        'Q26d' => 'Age of Chronically Homeless Persons',
        'Q26e' => 'Physical and Mental Health Conditions - Chronically Homeless Persons',
        'Q26f' => 'Client Cash Income - Chronically Homeless Persons',
        'Q26g' => 'Type of Cash Income Sources - Chronically Homeless Persons',
        'Q26h' => 'Type of Non-Cash Benefit Sources - Chronically Homeless Persons',
      }.freeze
    end
  end
end
