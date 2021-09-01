###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionSix < HudApr::Generators::Shared::Fy2020::QuestionSix
    QUESTION_TABLE_NUMBERS = ['Q6a'].freeze

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q6a_pii

      @report.complete(QUESTION_NUMBER)
    end
  end
end
