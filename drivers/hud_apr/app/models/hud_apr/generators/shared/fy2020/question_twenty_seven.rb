###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentySeven < Base
    QUESTION_NUMBER = 'Question 27'.freeze

    def self.table_descriptions
      {
        'Question 27' => 'Youth Questions',
        'Q27a' => 'Age of Youth',
        'Q27b' => 'Parenting Youth',
        'Q27c' => 'Gender - Youth',
        'Q27d' => 'Living Situation - Youth',
        'Q27e' => 'Length of Participation - Youth',
        'Q27f' => 'Exit Destination - Youth',
        'Q27g' => 'Cash Income - Sources - Youth',
        'Q27h' => 'Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status - Youth',
        'Q27i' => 'Disabling Conditions and Income for Youth at Exit',
      }.freeze
    end
  end
end
