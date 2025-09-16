###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2023
  class QuestionTwentyFour < HudApr::Generators::Shared::Fy2023::QuestionTwentyFour
    QUESTION_TABLE_NUMBERS = ['Q24'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q24_destination

      @report.complete(QUESTION_NUMBER)
    end
  end
end
