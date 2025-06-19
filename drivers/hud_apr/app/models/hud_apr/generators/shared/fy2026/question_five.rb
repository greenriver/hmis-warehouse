###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026
  class QuestionFive < Base
    include ::HudApr::Generators::Shared::Fy2026::Dq::QuestionOne

    QUESTION_NUMBER = 'Question 5'

    def self.table_descriptions
      {
        'Question 5' => 'Report Validations',
        'Q5a' => 'Report Validations Table',
      }.freeze
    end

    def q5_validations
      generate_q1(self.class::QUESTION_TABLE_NUMBER)
    end
  end
end
