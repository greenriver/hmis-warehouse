###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Dq::Fy2024
  class QuestionSeven < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionSeven

    QUESTION_NUMBER = 'Question 7'.freeze
    QUESTION_TABLE_NUMBER = 'Q7'.freeze

    def self.table_descriptions
      {
        'Question 7' => 'Inactive Records: Street Outreach & Emergency Shelter',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q7(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
