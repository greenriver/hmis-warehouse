###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionEighteen < HudApr::Generators::Shared::Fy2020::QuestionEighteen
    QUESTION_NUMBER = 'Question 18'.freeze
    QUESTION_TABLE_NUMBER = 'Q18'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q18_income

      @report.complete(QUESTION_NUMBER)
    end
  end
end
