###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionTwenty < Base
    QUESTION_NUMBER = 'Question 20'

    def self.table_descriptions
      {
        'Question 20' => 'Non-Cash Benefits',
        'Q20a' => 'Type of Non-Cash Benefit Sources',
        'Q20b' => 'Number of Non-Cash Benefit Sources',
      }.freeze
    end
  end
end
