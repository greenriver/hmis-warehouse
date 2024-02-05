###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class QuestionNineteen < HudApr::Generators::Shared::Fy2021::QuestionNineteen
    QUESTION_TABLE_NUMBERS = ['Q19b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q19b_disabling_conditions

      @report.complete(QUESTION_NUMBER)
    end
  end
end
