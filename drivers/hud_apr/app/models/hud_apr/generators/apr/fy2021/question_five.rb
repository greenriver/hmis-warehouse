###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionFive < HudApr::Generators::Shared::Fy2021::QuestionFive
    QUESTION_TABLE_NUMBER = 'Q5a'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q5_validations

      @report.complete(QUESTION_NUMBER)
    end
  end
end
