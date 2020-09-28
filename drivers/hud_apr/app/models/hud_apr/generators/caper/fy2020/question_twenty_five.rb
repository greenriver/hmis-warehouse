###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2020::QuestionTwentyFive
    QUESTION_NUMBER = 'Question 25'.freeze
    QUESTION_TABLE_NUMBERS = ['Q25a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans

      @report.complete(QUESTION_NUMBER)
    end
  end
end
