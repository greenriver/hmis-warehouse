###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2024
  class QuestionTen < HudApr::Generators::Shared::Fy2024::QuestionTen
    QUESTION_TABLE_NUMBERS = ['Q10a', 'Q10d'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q10a_gender_of_adults
      # 10b and 10c removed in 2024
      q10d_gender_by_age_range

      @report.complete(QUESTION_NUMBER)
    end
  end
end
