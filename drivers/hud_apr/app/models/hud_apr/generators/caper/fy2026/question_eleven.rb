###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2026
  class QuestionEleven < HudApr::Generators::Shared::Fy2026::QuestionEleven
    QUESTION_TABLE_NUMBER = 'Q11'

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q11_ages

      @report.complete(QUESTION_NUMBER)
    end
  end
end
