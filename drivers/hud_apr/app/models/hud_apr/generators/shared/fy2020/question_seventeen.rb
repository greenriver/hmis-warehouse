###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionSeventeen < Base
    QUESTION_NUMBER = 'Question 17'

    def self.table_descriptions
      {
        'Question 17' => 'Cash Income - Sources',
      }.freeze
    end
  end
end
