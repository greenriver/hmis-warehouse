###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Apr::Fy2023
  class QuestionSixteen < HudApr::Generators::Shared::Fy2023::QuestionSixteen
    QUESTION_TABLE_NUMBER = 'Q16'

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q16_cash_ranges

      @report.complete(QUESTION_NUMBER)
    end
  end
end
