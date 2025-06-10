###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2026
  class QuestionFifteen < Base
    include HudReports::LivingSituationsQuestion

    QUESTION_NUMBER = 'Question 15'

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
