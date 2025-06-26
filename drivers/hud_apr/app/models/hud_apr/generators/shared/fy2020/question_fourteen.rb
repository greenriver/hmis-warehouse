###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionFourteen < Base
    QUESTION_NUMBER = 'Question 14'

    def self.table_descriptions
      {
        'Question 14' => 'Domestic Violence',
        'Q14a' => 'Domestic Violence History',
        'Q14b' => 'Persons Fleeing Domestic Violence',
      }.freeze
    end
  end
end
