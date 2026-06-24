###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudDataQualityReport::Generators::Fy2020
  class QuestionTwo < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 2'.freeze
    QUESTION_TABLE_NUMBER = 'Q2'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 2' => 'Personally Identifiable Information (PII)',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
