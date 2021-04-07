###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionSeventeen < HudApr::Generators::Shared::Fy2020::QuestionSeventeen
    QUESTION_TABLE_NUMBER = 'Q17'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q17_cash_sources

      @report.complete(QUESTION_NUMBER)
    end
  end
end
