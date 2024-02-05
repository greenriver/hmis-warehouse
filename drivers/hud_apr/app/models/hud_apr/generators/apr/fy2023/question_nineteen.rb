###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2023
  class QuestionNineteen < HudApr::Generators::Shared::Fy2023::QuestionNineteen
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2', 'Q19b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q19a_stayers
      q19a_leavers
      q19b_disabling_conditions

      @report.complete(QUESTION_NUMBER)
    end
  end
end
