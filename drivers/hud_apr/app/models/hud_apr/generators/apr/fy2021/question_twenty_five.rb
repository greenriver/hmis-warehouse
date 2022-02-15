###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2021::QuestionTwentyFive
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25e', 'Q25f', 'Q25g', 'Q25h', 'Q25i'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans
      q25b_number_of_households
      q25c_veteran_gender
      q25d_veteran_age
      q25e_health_conditions
      q25f_income
      q25g_income_sources
      q25h_non_cash_benefits
      q25i_destination

      @report.complete(QUESTION_NUMBER)
    end
  end
end
