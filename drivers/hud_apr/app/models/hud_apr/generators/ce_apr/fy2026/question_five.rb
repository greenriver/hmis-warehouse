###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::CeApr::Fy2026
  class QuestionFive < HudApr::Generators::Shared::Fy2026::QuestionFive
    include HudApr::Generators::CeApr::Fy2026::QuestionConcern
    QUESTION_TABLE_NUMBER = 'Q5a'

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q5_validations

      @report.complete(QUESTION_NUMBER)
    end

    private def intentionally_blank
      [
        'B6',
        'C6',
        'B7',
        'C7',
        'B8',
        'C8',
        'B9',
        'C9',
        'B10',
        'C10',
        'B12',
        'C12',
        'B14',
        'C14',
        'B17',
        'C17',
      ]
    end
  end
end
