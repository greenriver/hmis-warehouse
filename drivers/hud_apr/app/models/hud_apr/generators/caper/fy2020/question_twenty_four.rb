###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2020::QuestionTwentyFour
    QUESTION_NUMBER = 'Question 24'.freeze
    QUESTION_TABLE_NUMBERS = ['Q24'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24_destination

      @report.complete(QUESTION_NUMBER)
    end
  end
end
