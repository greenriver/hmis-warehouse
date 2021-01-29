###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwelve < HudApr::Generators::Shared::Fy2020::QuestionTwelve
    QUESTION_NUMBER = 'Question 12'.freeze
    QUESTION_TABLE_NUMBERS = ['Q12a', 'Q12b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q12a_race
      q12b_ethnicity

      @report.complete(QUESTION_NUMBER)
    end
  end
end
