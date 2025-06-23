###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Dq::Fy2026
  class QuestionThree < Base
    include ::HudApr::Generators::Shared::Fy2026::Dq::QuestionThree

    QUESTION_NUMBER = 'Question 3'
    QUESTION_TABLE_NUMBER = 'Q3'

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
