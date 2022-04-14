###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionThirteen < Base
    QUESTION_NUMBER = 'Question 13'.freeze

    def self.table_descriptions
      {
        'Question 13' => 'Physical and Mental Health Conditions',
        'Q13a1' => 'Physical and Mental Health Conditions at Start',
        'Q13b1' => 'Physical and Mental Health Conditions at Exit',
        'Q13c1' => 'Physical and Mental Health Conditions for Stayers',
        'Q13a2' => 'Number of Conditions at Start',
        'Q13b2' => 'Number of Conditions at Exit',
        'Q13c2' => 'Number of Conditions for Stayers',
      }.freeze
    end
  end
end
