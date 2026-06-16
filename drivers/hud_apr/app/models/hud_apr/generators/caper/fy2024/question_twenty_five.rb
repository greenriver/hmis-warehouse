###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2024
  class QuestionTwentyFive < HudApr::Generators::Shared::Fy2024::QuestionTwentyFive
    QUESTION_TABLE_NUMBERS = ['Q25a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q25a_number_of_veterans

      @report.complete(QUESTION_NUMBER)
    end
  end
end
