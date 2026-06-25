###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionEleven < Base
    QUESTION_NUMBER = 'Question 11'

    def self.table_descriptions
      {
        'Question 11' => 'Age',
      }.freeze
    end
  end
end
