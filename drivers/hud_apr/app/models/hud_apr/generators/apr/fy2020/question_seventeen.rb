###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionSeventeen < HudApr::Generators::Shared::Fy2020::QuestionSeventeen
    QUESTION_NUMBER = 'Question 17'.freeze
    QUESTION_TABLE_NUMBER = 'Q17'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q17_cash_sources

      @report.complete(QUESTION_NUMBER)
    end
  end
end
