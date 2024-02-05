###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class QuestionThree < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionThree

    QUESTION_NUMBER = 'Question 3'.freeze
    QUESTION_TABLE_NUMBER = 'Q3'.freeze

    def self.table_descriptions
      {
        'Question 3' => 'Universal Data Elements',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q3(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
