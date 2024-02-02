###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionFour < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 4'.freeze
    QUESTION_TABLE_NUMBER = 'Q4'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 4' => 'Income and Housing Data Quality',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
