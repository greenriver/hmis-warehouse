###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentyTwo < HudApr::Generators::Shared::Fy2020::QuestionTwentyTwo
    QUESTION_NUMBER = 'Question 22'.freeze
    QUESTION_TABLE_NUMBERS = ['Q22a1', 'Q22b', 'Q22c', 'Q22e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q22a1_length_of_participation
      q22b_average_length_of_participation
      q22c_start_to_move_in
      q22e_time_prior_to_housing

      @report.complete(QUESTION_NUMBER)
    end
  end
end
