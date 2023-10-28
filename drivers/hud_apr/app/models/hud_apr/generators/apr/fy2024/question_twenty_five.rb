###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2024::QuestionTwentyFive
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25i', 'Q25j'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans
      q25b_number_of_households
      q25c_veteran_gender
      q25d_veteran_age
      q25i_destination
      q25j_exit_destination_subsidy

      @report.complete(QUESTION_NUMBER)
    end
  end
end
