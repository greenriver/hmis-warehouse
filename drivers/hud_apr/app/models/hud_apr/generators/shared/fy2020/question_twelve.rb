###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwelve < Base
    QUESTION_NUMBER = 'Question 12'.freeze

    def self.table_descriptions
      {
        'Question 12' => 'Race & Ethnicity',
        'Q12a' => 'Race',
        'Q12b' => 'Ethnicity',
      }.freeze
    end
  end
end
