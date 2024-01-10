###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionFive < Base
    include ::HudApr::Generators::Shared::Fy2024::Dq::QuestionOne

    QUESTION_NUMBER = 'Question 5'.freeze

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
