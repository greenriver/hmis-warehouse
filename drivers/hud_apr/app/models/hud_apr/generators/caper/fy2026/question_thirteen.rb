###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2026
  class QuestionThirteen < HudApr::Generators::Shared::Fy2026::QuestionThirteen
    QUESTION_TABLE_NUMBERS = [
      'Q13a1',
      'Q13b1',
      'Q13c1',
    ].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q13x1_conditions

      @report.complete(QUESTION_NUMBER)
    end
  end
end
