###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2023
  class QuestionTwentyOne < HudApr::Generators::Shared::Fy2023::QuestionTwentyOne
    QUESTION_TABLE_NUMBERS = ['Q21'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q21_health_insurance

      @report.complete(QUESTION_NUMBER)
    end
  end
end
