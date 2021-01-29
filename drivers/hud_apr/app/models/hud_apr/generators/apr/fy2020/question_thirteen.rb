###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionThirteen < HudApr::Generators::Shared::Fy2020::QuestionThirteen
    QUESTION_NUMBER = 'Question 13'.freeze
    QUESTION_TABLE_NUMBERS = [
      'Q13a1',
      'Q13b1',
      'Q13c1',
      'Q13a2',
      'Q13b2',
      'Q13c2',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q13x1_conditions
      q13x2_condition_counts

      @report.complete(QUESTION_NUMBER)
    end
  end
end
