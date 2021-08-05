###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionEight < HudApr::Generators::Shared::Fy2020::QuestionEight
    QUESTION_TABLE_NUMBERS = ['Q8a', 'Q8b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q8a_persons_served

      @report.complete(QUESTION_NUMBER)
    end

    private def q8a_intentionally_blank
      [
        'B3',
        'C3',
        'D3',
        'E3',
        'F3',
      ]
    end
  end
end
