###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2024
  class QuestionSix < HudApr::Generators::Shared::Fy2024::QuestionSix
    include HudApr::Generators::CeApr::Fy2024::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q6a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q6a_pii

      @report.complete(QUESTION_NUMBER)
    end
  end
end
