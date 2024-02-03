###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTen < HudApr::Generators::Shared::Fy2024::QuestionTen
    QUESTION_TABLE_NUMBERS = ['Q10a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q10a_gender_of_adults

      @report.complete(QUESTION_NUMBER)
    end
  end
end
