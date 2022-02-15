###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Caper::Fy2020
  class QuestionTwenty < HudApr::Generators::Shared::Fy2020::QuestionTwenty
    QUESTION_TABLE_NUMBERS = ['Q20a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q20a_types

      @report.complete(QUESTION_NUMBER)
    end
  end
end
