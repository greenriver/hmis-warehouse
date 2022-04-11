###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFour < Base
    QUESTION_NUMBER = 'Question 24'.freeze

    def self.table_descriptions
      {
        'Question 24' => 'Homelessness Prevention Housing Assessment at Exit',
      }.freeze
    end
  end
end
