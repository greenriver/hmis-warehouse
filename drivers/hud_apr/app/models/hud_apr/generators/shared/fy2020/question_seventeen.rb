###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSeventeen < Base
    QUESTION_NUMBER = 'Question 17'.freeze

    def self.table_descriptions
      {
        'Question 17' => 'Cash Income - Sources',
      }.freeze
    end
  end
end
