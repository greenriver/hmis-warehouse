###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2020::QuestionTwentyFive
    QUESTION_NUMBER = 'Question 25'.freeze
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25e', 'Q25f', 'Q25g', 'Q25h', 'Q25i'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans
      q25b_number_of_households
      q25c_veteran_gender
      q25d_veteran_age

      @report.complete(QUESTION_NUMBER)
    end
  end
end
