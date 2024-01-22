###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class QuestionSix < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionSix

    QUESTION_NUMBER = 'Question 6'.freeze
    QUESTION_TABLE_NUMBER = 'Q6'.freeze

    def self.table_descriptions
      {
        'Question 6' => 'Timeliness',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q6(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
