###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionSixteen < HudApr::Generators::Shared::Fy2020::QuestionSixteen
    QUESTION_TABLE_NUMBER = 'Q16'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q16_cash_ranges

      @report.complete(QUESTION_NUMBER)
    end
  end
end
