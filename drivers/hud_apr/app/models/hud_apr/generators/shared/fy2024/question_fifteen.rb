###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionFifteen < Base
    QUESTION_NUMBER = 'Question 15'.freeze

    def self.table_descriptions
      {
        'Question 15' => 'Living Situation',
      }.freeze
    end

    private def q15_living_situation
      living_situations_question(question: 'Q15', members: universe.members.where(adult_or_hoh_clause))
    end
  end
end
