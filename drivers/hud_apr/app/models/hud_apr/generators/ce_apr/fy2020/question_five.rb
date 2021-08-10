###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class QuestionFive < HudApr::Generators::Shared::Fy2020::QuestionFive
    QUESTION_TABLE_NUMBER = 'Q5a'.freeze

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q5_validations

      @report.complete(QUESTION_NUMBER)
    end

    private def intentionally_blank
      [
        'B5',
        'B6',
        'B7',
        'B8',
        'B9',
        'B11',
        'B13',
        'B16',
      ]
    end
  end
end
