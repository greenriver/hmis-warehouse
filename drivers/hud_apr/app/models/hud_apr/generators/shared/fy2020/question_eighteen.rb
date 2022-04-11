###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEighteen < Base
    QUESTION_NUMBER = 'Question 18'.freeze

    def self.table_descriptions
      {
        'Question 18' => 'Client Cash Income Category - Earned/Other Income Category - by Start and Annual Assessment/Exit Status',
      }.freeze
    end
  end
end
