###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2024::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24b', 'Q24c', 'Q24d'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24b_moving_on_assistance_provided_to_households_in_psh
      q24c_sexual_orientation_of_adults_in_psh_in_psh
      q24d_language_of_persons_requiring_translation_assistance

      @report.complete(QUESTION_NUMBER)
    end
  end
end
