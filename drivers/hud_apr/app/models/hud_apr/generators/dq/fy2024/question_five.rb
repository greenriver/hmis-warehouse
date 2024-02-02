###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class QuestionFive < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionFive

    QUESTION_NUMBER = 'Question 5'.freeze
    QUESTION_TABLE_NUMBER = 'Q5'.freeze

    def self.table_descriptions
      {
        'Question 5' => 'Chronic Homelessness',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q5(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
