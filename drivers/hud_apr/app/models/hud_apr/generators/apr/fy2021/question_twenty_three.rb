###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionTwentyThree < HudApr::Generators::Shared::Fy2021::QuestionTwentyThree
    QUESTION_TABLE_NUMBERS = ['Q23c'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q23c_destination

      @report.complete(QUESTION_NUMBER)
    end
  end
end
