###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionSeven < HudApr::Generators::Shared::Fy2020::QuestionSeven
    QUESTION_TABLE_NUMBERS = ['Q7a', 'Q7b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q7a_persons_served
      q7b_pit_count

      @report.complete(QUESTION_NUMBER)
    end
  end
end
