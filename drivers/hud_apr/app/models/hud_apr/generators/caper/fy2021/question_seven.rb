###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class QuestionSeven < HudApr::Generators::Shared::Fy2021::QuestionSeven
    QUESTION_TABLE_NUMBERS = ['Q7a', 'Q7b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q7a_persons_served
      q7b_pit_count

      @report.complete(QUESTION_NUMBER)
    end
  end
end
