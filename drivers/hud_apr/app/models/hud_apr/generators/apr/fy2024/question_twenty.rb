###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2024
  class QuestionTwenty < HudApr::Generators::Shared::Fy2024::QuestionTwenty
    QUESTION_TABLE_NUMBERS = ['Q20a', 'Q20b'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q20a_types
      q20b_sources

      @report.complete(QUESTION_NUMBER)
    end
  end
end
