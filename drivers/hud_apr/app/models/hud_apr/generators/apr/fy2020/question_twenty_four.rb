###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2020::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24_destination
      q24_populations
      q24_assessment

      @report.complete(QUESTION_NUMBER)
    end
  end
end
