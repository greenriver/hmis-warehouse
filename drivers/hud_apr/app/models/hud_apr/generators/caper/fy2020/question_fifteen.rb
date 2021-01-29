###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionFifteen < HudApr::Generators::Shared::Fy2020::QuestionFifteen
    QUESTION_NUMBER = 'Question 15'.freeze
    QUESTION_TABLE_NUMBER = 'Q15'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q15_living_situation

      @report.complete(QUESTION_NUMBER)
    end
  end
end
