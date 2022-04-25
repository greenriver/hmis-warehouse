###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionSeventeen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q17: Services Provided'.freeze
    QUESTION_TABLE_NUMBER = 'Q17'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Type of Service',
      'Number of people receiving service',
    ].freeze

    ROWS = {
      '17a. Reengagement' => 1,
      '17b. Screening' => 2,
      '17c. Clinical Assessment' => 14,
      '17d. Habilitation/rehabilitation' => 3,
      '17e. Community mental health' => 4,
      '17f. Substance use treatment' => 5,
      '17g. Case management' => 6,
      '17h. Residential supportive services' => 7,
      '17i. Housing minor renovation' => 8,
      '17j. Housing moving assistance' => 9,
      '17k. Housing eligibility determination' => 10,
      '17l. Security deposits' => 11,
      '17m. One-time rent for eviction prevention' => 12,
    }.freeze

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
