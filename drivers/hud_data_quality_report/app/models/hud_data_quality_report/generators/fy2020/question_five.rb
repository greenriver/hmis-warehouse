###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionFive < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 5'.freeze
    QUESTION_TABLE_NUMBER = 'Q5'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 5' => 'Chronic Homelessness',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
