###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionSixteen < HudApr::Generators::Shared::Fy2020::QuestionSixteen
    QUESTION_NUMBER = 'Question 16'.freeze
    QUESTION_TABLE_NUMBER = 'Q16'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q16_cash_ranges

      @report.complete(QUESTION_NUMBER)
    end
  end
end
