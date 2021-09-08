###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2021::QuestionTwentyFive
    QUESTION_TABLE_NUMBERS = ['Q25a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans

      @report.complete(QUESTION_NUMBER)
    end
  end
end
