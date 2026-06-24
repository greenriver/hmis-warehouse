###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionTwelve < Base
    QUESTION_NUMBER = 'Question 12'

    def self.table_descriptions
      {
        'Question 12' => 'Race & Ethnicity',
        'Q12a' => 'Race',
        'Q12b' => 'Ethnicity',
      }.freeze
    end
  end
end
