###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentySix < HudApr::Generators::Shared::Fy2020::QuestionTwentySix
    QUESTION_NUMBER = 'Question 26'.freeze
    QUESTION_TABLE_NUMBERS = ['Q26b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q26b_chronic_people

      @report.complete(QUESTION_NUMBER)
    end
  end
end
