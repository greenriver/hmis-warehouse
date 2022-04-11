###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFive < Base
    QUESTION_NUMBER = 'Question 25'.freeze

    def self.table_descriptions
      {
        'Question 25' => 'Veterans Questions',
        'Q25a' => 'Number of Veterans',
        'Q25b' => 'Number of Veteran Households',
        'Q25c' => 'Gender – Veterans',
        'Q25d' => 'Age – Veterans',
        'Q25e' => 'Physical and Mental Health Conditions – Veterans',
        'Q25f' => 'Cash Income Category - Income Category - by Start and Annual /Exit Status – Veterans',
        'Q25g' => 'Type of Cash Income Sources – Veterans',
        'Q25h' => 'Type of Non-Cash Benefit Sources – Veterans',
        'Q25i' => 'Exit Destination – Veterans',
      }.freeze
    end
  end
end
