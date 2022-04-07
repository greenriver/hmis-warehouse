###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionSeven < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 7'.freeze
    QUESTION_TABLE_NUMBER = 'Q7'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 7' => 'Inactive Records: Street Outreach & Emergency Shelter',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
