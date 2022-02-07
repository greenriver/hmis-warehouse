###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2021
  class QuestionEleven < HudApr::Generators::Shared::Fy2021::QuestionEleven
    QUESTION_TABLE_NUMBER = 'Q11'.freeze

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q11_ages

      @report.complete(QUESTION_NUMBER)
    end
  end
end
