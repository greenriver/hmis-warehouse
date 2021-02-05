###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionEight < HudApr::Generators::Shared::Fy2020::QuestionEight
    include ArelHelper

    QUESTION_NUMBER = 'Question 8'.freeze
    QUESTION_TABLE_NUMBERS = ['Q8a', 'Q8b'].freeze

    HEADER_ROW = [
      ' ',
      'Total',
      'Without Children',
      'With Children and Adults',
      'With Only Children',
      'Unknown Household Type',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q8a_persons_served
      q8b_pit_count

      @report.complete(QUESTION_NUMBER)
    end
  end
end
