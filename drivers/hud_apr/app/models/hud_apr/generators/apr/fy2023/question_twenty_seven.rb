###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2023
  class QuestionTwentySeven < HudApr::Generators::Shared::Fy2023::QuestionTwentySeven
    QUESTION_TABLE_NUMBERS = ['Q27a', 'Q27b', 'Q27c', 'Q27d', 'Q27e', 'Q27f', 'Q27g', 'Q27h', 'Q27i', 'Q27j', 'Q27k', 'Q27l'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q27a_youth_age
      q27b_parenting_youth
      q27c_youth_gender
      q27d_youth_living_situation
      q27e_youth_length_of_participation
      q27f_youth_destination
      q27g_youth_income_sources
      q27h_youth_earned_income
      q27i_youth_disabling_conditions
      q27j_average_length_of_participation
      q27k_start_to_move_in
      q27l_time_prior_to_housing
      q27j_average_length_of_participation
      q27k_start_to_move_in
      q27l_time_prior_to_housing

      @report.complete(QUESTION_NUMBER)
    end
  end
end
