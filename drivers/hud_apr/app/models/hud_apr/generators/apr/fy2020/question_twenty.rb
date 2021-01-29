###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionTwenty < HudApr::Generators::Shared::Fy2020::QuestionTwenty
    QUESTION_NUMBER = 'Question 20'.freeze
    QUESTION_TABLE_NUMBERS = ['Q20a', 'Q20b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q20a_types
      q20b_sources

      @report.complete(QUESTION_NUMBER)
    end
  end
end
