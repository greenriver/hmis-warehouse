###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSix < Base
    QUESTION_NUMBER = 'Question 6'.freeze

    def self.table_descriptions
      {
        'Question 6' => 'Data Quality',
        'Q6a' => 'Personally Identifiable Information',
        'Q6b' => 'Universal Data Elements',
        'Q6c' => 'Income and Housing Data Quality',
        'Q6d' => 'Chronic Homelessness',
        'Q6e' => 'Timeliness',
        'Q6f' => 'Inactive Records: Street Outreach and Emergency Shelter',
      }.freeze
    end
  end
end
