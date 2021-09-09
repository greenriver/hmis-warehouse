###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2021
  class QuestionTwentySix < HudApr::Generators::Shared::Fy2021::QuestionTwentySix
    QUESTION_TABLE_NUMBERS = ['Q26b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q26b_chronic_people

      @report.complete(QUESTION_NUMBER)
    end
  end
end
