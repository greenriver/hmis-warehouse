###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::Shared::Fy2020
  class QuestionNine < Base
    QUESTION_NUMBER = 'Question 9'

    def self.table_descriptions
      {
        'Question 9' => 'Contacts and Engagements',
        'Q9a' => 'Number of Persons Contacted',
        'Q9b' => 'Number of Persons Engaged',
      }.freeze
    end
  end
end
