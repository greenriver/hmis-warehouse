###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentyTwo < HudApr::Generators::Shared::Fy2020::QuestionTwentyTwoBase
    QUESTION_NUMBER = 'Question 22'.freeze
    QUESTION_TABLE_NUMBERS = ['Q22a2', 'Q22b', 'Q22c', 'Q22d', 'Q22e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q22a2_length_of_participation

      @report.complete(QUESTION_NUMBER)
    end
  end
end
