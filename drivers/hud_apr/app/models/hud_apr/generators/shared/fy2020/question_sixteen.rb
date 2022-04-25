###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSixteen < Base
    QUESTION_NUMBER = 'Question 16'.freeze

    def self.table_descriptions
      {
        'Question 16' => 'Cash Income - Ranges',
      }.freeze
    end
  end
end
