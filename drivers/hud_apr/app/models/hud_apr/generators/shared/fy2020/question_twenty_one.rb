###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyOne < Base
    QUESTION_NUMBER = 'Question 21'.freeze

    def self.table_descriptions
      {
        'Question 21' => 'Health Insurance',
      }.freeze
    end
  end
end
