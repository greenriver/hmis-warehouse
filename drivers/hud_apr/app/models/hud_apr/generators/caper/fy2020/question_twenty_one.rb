###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentyOne < HudApr::Generators::Shared::Fy2020::QuestionTwentyOne
    QUESTION_NUMBER = 'Question 21'.freeze
    QUESTION_TABLE_NUMBERS = ['Q21'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q21_health_insurance

      @report.complete(QUESTION_NUMBER)
    end
  end
end
