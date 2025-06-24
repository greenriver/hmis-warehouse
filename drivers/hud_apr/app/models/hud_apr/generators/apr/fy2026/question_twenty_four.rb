###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Apr::Fy2026
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2026::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24b', 'Q24d', 'Q24e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24b_moving_on_assistance_provided_to_households_in_psh
      q24d_language_of_persons_requiring_translation_assistance
      q24e_sex

      @report.complete(QUESTION_NUMBER)
    end
  end
end
