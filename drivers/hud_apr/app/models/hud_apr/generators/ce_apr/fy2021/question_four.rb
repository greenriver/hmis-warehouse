###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class QuestionFour < HudApr::Generators::Shared::Fy2021::QuestionFour
    include HudApr::Generators::CeApr::Fy2021::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end
  end
end
