###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2024
  class QuestionTwelve < HudApr::Generators::Shared::Fy2024::QuestionTwelve
    QUESTION_TABLE_NUMBERS = ['Q12'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q12a_race_and_ethnicity

      @report.complete(QUESTION_NUMBER)
    end
  end
end
