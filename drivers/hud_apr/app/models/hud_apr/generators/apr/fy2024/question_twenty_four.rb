###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2024::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24b', 'Q24c', 'Q24d'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q23c_destination
      q23d_subsidy_type

      @report.complete(QUESTION_NUMBER)
    end
  end
end
