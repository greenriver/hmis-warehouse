###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Dq::Fy2026
  class QuestionOne < Base
    include ::HudApr::Generators::Shared::Fy2026::Dq::QuestionOne

    QUESTION_NUMBER = 'Question 1'
    QUESTION_TABLE_NUMBER = 'Q1'

    def self.table_descriptions
      {
        'Question 1' => 'Report Validation Table',
      }.freeze
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      generate_q1(self.class::QUESTION_TABLE_NUMBER)

      @report.complete(QUESTION_NUMBER)
    end
  end
end
