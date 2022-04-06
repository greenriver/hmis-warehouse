###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyThree < Base
    QUESTION_NUMBER = 'Question 23'.freeze

    def self.table_descriptions
      {
        'Question 23' => '',
        'Q23c' => 'Exit Destination',
      }.freeze
    end
  end
end
