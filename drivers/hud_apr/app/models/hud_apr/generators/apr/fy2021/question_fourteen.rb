###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionFourteen < HudApr::Generators::Shared::Fy2021::QuestionFourteen
    QUESTION_TABLE_NUMBERS = ['Q14a', 'Q14b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q14a_dv_history
      q14b_dv_fleeing

      @report.complete(QUESTION_NUMBER)
    end
  end
end
