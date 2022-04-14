###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFourteen < Base
    QUESTION_NUMBER = 'Question 14'.freeze

    def self.table_descriptions
      {
        'Question 14' => 'Domestic Violence',
        'Q14a' => 'Domestic Violence History',
        'Q14b' => 'Persons Fleeing Domestic Violence',
      }.freeze
    end
  end
end
