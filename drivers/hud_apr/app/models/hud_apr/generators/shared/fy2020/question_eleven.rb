###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEleven < Base
    QUESTION_NUMBER = 'Question 11'.freeze

    def self.table_descriptions
      {
        'Question 11' => 'Age',
      }.freeze
    end
  end
end
