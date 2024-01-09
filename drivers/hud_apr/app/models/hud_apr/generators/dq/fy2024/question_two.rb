###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class QuestionTwo < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionTwo

    QUESTION_NUMBER = 'Question 2'.freeze
    QUESTION_TABLE_NUMBER = 'Q2'.freeze

    def self.table_descriptions
      {
        'Question 2' => 'Personally Identifiable Information (PII)',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q2(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
