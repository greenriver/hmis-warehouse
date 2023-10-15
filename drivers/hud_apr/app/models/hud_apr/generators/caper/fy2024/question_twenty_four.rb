###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2024
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2024::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24a', 'Q24d'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24a_homelessness_prevention_housing_assessment_at_exit
      q24d_language_of_persons_requiring_translation_assistance

      @report.complete(QUESTION_NUMBER)
    end
  end
end
