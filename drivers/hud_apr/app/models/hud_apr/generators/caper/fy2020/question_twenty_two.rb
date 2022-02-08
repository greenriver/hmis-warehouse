###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwentyTwo < HudApr::Generators::Shared::Fy2020::QuestionTwentyTwo
    QUESTION_TABLE_NUMBERS = ['Q22a2', 'Q22c', 'Q22d', 'Q22e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q22a2_length_of_participation
      q22c_start_to_move_in
      q22d_participation_by_household_type
      q22e_time_prior_to_housing

      @report.complete(QUESTION_NUMBER)
    end
  end
end
