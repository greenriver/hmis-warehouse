###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class QuestionSeven < HudApr::Generators::Shared::Fy2021::QuestionSeven
    include HudApr::Generators::CeApr::Fy2021::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q7a'].freeze

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q7a_persons_served

      @report.complete(QUESTION_NUMBER)
    end

    private def row_seven_cells
      []
    end
  end
end
