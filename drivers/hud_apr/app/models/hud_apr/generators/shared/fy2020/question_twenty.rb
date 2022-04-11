###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwenty < Base
    QUESTION_NUMBER = 'Question 20'.freeze

    def self.table_descriptions
      {
        'Question 20' => 'Non-Cash Benefits',
        'Q20a' => 'Type of Non-Cash Benefit Sources',
        'Q20b' => 'Number of Non-Cash Benefit Sources',
      }.freeze
    end
  end
end
