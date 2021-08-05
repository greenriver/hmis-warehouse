###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionFour < HudApr::Generators::Shared::Fy2020::QuestionFour
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      # FIXME: this needs to inspect the resulting AprClients to determine which projects to include
      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end
  end
end
