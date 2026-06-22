###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFour < Base
    QUESTION_NUMBER = 'Question 24'

    def self.table_descriptions
      {
        'Question 24' => 'Homelessness Prevention Housing Assessment at Exit',
      }.freeze
    end
  end
end
