###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionNineteen < HudApr::Generators::Shared::Fy2020::QuestionNineteen
    QUESTION_NUMBER = 'Question 19'.freeze
    QUESTION_TABLE_NUMBERS = ['Q19a1', 'Q19a2', 'Q19b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q19a_stayers
      q19a_leavers
      q19b_disabling_conditions

      @report.complete(QUESTION_NUMBER)
    end
  end
end
