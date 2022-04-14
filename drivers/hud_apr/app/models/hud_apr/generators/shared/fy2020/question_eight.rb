###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEight < Base
    QUESTION_NUMBER = 'Question 8'.freeze

    HEADER_ROW = [
      ' ',
      'Total',
      'Without Children',
      'With Children and Adults',
      'With Only Children',
      'Unknown Household Type',
    ].freeze

    def self.table_descriptions
      {
        'Question 8' => 'Households Served',
        'Q8a' => 'Number of Households Served',
        'Q8b' => 'Point-in-Time Count of Households on the Last Wednesday',
      }.freeze
    end
  end
end
