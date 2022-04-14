###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionEighteen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q18: Referrals Provided'.freeze
    QUESTION_TABLE_NUMBER = 'Q18'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Type of Referral',
      'Number receiving each referral',
      'Number who attained the service from the referral',
    ].freeze

    ROWS = {
      'Community mental health' => 1,
      'Substance use treatment' => 2,
      'Primary health/dental care' => 3,
      'Job training' => 4,
      'Educational services' => 5,
      'Housing Services' => 6,
      'Temporary housing' => 11,
      'Permanent housing' => 7,
      'Income assistance' => 8,
      'Employment assistance' => 9,
      'Medical Insurance' => 10,
    }.freeze

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
