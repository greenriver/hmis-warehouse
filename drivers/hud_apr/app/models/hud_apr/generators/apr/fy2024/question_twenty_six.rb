###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwentySix < HudApr::Generators::Shared::Fy2024::QuestionTwentySix
    QUESTION_TABLE_NUMBERS = ['Q26a', 'Q26b', 'Q26c', 'Q26d', 'Q26e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q26a_chronic_households
      q26b_chronic_people
      q26c_ch_gender
      q26d_ch_age
      q26e_health_conditions

      @report.complete(QUESTION_NUMBER)
    end
  end
end
