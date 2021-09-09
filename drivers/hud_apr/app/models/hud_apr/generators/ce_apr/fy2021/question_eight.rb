###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class QuestionEight < HudApr::Generators::Shared::Fy2021::QuestionEight
    include HudApr::Generators::CeApr::Fy2021::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q8a'].freeze

    def needs_ce_assessments?
      true
    end

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
