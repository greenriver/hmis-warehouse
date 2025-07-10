###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionEighteen < Base
    QUESTION_NUMBER = 'Question 18'

    def self.table_descriptions
      {
        'Question 18' => 'Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status',
      }.freeze
    end
  end
end
