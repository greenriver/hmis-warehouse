###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2024
  class QuestionTwentyTwo < HudApr::Generators::Shared::Fy2024::QuestionTwentyTwo
    QUESTION_TABLE_NUMBERS = ['Q22a2', 'Q22c', 'Q22d', 'Q22e', 'Q22f', 'Q22g'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q22a2_length_of_participation
      q22c_start_to_move_in
      q22d_participation_by_household_type
      q22e_time_prior_to_housing
      q22f_start_to_move_in_by_race_and_ethnicity
      q22g_time_prior_to_housing_by_race_and_ethnicity

      @report.complete(QUESTION_NUMBER)
    end
  end
end
