###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionTwentySix < HudApr::Generators::Shared::Fy2021::QuestionTwentySix
    QUESTION_TABLE_NUMBERS = ['Q26a', 'Q26b', 'Q26c', 'Q26d', 'Q26e', 'Q26f', 'Q26g', 'Q26h'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q26a_chronic_households
      q26b_chronic_people
      q26c_ch_gender
      q26d_ch_age
      q26e_health_conditions
      q26f_income
      q26g_income_sources
      q26h_non_cash_benefits

      @report.complete(QUESTION_NUMBER)
    end
  end
end
