###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Caper::Fy2024
  class QuestionFour < HudApr::Generators::Shared::Fy2024::QuestionFour
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end
  end
end
