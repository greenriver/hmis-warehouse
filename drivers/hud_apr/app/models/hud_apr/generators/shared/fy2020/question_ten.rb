###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionTen < Base
    QUESTION_NUMBER = 'Question 10'

    def self.table_descriptions
      {
        'Question 10' => 'Gender',
        'Q10a' => 'Gender of Adults',
        'Q10b' => 'Gender of Children',
        'Q10c' => 'Gender of Persons Missing Age Information',
        'Q10d' => 'Gender by Age Ranges',
      }.freeze
    end
  end
end
