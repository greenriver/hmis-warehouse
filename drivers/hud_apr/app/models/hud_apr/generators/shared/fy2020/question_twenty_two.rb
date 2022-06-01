###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyTwo < Base
    QUESTION_NUMBER = 'Question 22'.freeze

    def self.table_descriptions
      {
        'Question 22' => 'Length of participation',
        'Q22a1' => 'Length of Participation - CoC Projects',
        'Q22a2' => 'Length of Participation - ESG Projects',
        'Q22b' => 'Average and Median Length of Participation in Days',
        'Q22c' => 'Length of Time between Project Start Date and Housing Move-in Date',
        'Q22d' => 'Length of Participation by Household Type',
        'Q22e' => 'Length of Time Prior to Housing - based on 3.917 Date Homelessness Started',
      }.freeze
    end
  end
end
