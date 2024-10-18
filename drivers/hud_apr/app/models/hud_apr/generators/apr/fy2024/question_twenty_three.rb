###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwentyThree < HudApr::Generators::Shared::Fy2024::QuestionTwentyThree
    QUESTION_TABLE_NUMBERS = ['Q23c', 'Q23d', 'Q23e'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q23c_destination
      q23d_subsidy_type
      q23e_destination_type_by_race_and_ethnicity

      @report.complete(QUESTION_NUMBER)
    end
  end
end
