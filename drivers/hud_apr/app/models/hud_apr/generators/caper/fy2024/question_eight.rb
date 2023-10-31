###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2024
  class QuestionEight < HudApr::Generators::Shared::Fy2024::QuestionEight
    QUESTION_TABLE_NUMBERS = ['Q8a', 'Q8b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q8a_persons_served
      q8b_pit_count

      @report.complete(QUESTION_NUMBER)
    end
  end
end
