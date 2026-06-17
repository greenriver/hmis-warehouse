###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Apr::Fy2026
  class QuestionFifteen < HudApr::Generators::Shared::Fy2026::QuestionFifteen
    QUESTION_TABLE_NUMBER = 'Q15'

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q15_living_situation

      @report.complete(QUESTION_NUMBER)
    end
  end
end
