###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionSix < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 6'.freeze
    QUESTION_TABLE_NUMBER = 'Q6'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 6' => 'Timeliness',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
