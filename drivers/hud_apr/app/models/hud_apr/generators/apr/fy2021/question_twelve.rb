###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionTwelve < HudApr::Generators::Shared::Fy2021::QuestionTwelve
    QUESTION_TABLE_NUMBERS = ['Q12a', 'Q12b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q12a_race
      q12b_ethnicity

      @report.complete(QUESTION_NUMBER)
    end
  end
end
