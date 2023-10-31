###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionEighteen < HudApr::Generators::Shared::Fy2024::QuestionEighteen
    QUESTION_TABLE_NUMBER = 'Q18'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q18_income

      @report.complete(QUESTION_NUMBER)
    end
  end
end
