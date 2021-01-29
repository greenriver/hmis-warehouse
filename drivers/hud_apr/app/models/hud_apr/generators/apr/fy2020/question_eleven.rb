###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionEleven < HudApr::Generators::Shared::Fy2020::QuestionEleven
    QUESTION_NUMBER = 'Question 11'.freeze
    QUESTION_TABLE_NUMBER = 'Q11'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      q11_ages

      @report.complete(QUESTION_NUMBER)
    end
  end
end
