###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionFifteen < Base
    QUESTION_NUMBER = 'Question 15'

    def self.table_descriptions
      {
        'Question 15' => 'Living Situation',
      }.freeze
    end
  end
end
