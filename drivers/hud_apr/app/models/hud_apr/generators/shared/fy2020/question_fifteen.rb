###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
