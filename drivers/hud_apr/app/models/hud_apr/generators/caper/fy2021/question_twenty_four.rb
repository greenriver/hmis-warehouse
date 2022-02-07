###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2021::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24_destination

      @report.complete(QUESTION_NUMBER)
    end
  end
end
