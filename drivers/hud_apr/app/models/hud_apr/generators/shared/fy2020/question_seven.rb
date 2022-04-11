###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSeven < Base
    QUESTION_NUMBER = 'Question 7'.freeze

    def self.table_descriptions
      {
        'Question 7' => 'Persons Served',
        'Q7a' => 'Number of Persons Served',
        'Q7b' => 'Point-in-Time Count of Persons on the Last Wednesday',
      }.freeze
    end
  end
end
