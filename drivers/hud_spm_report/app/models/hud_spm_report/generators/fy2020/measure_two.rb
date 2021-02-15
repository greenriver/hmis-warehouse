###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureTwo < Base
    def self.question_number
      'Measure 2'.freeze
    end

    TABLE_NUMBERS = ['2a', '2b'].freeze

    PERMANENT_DESTINATIONS = [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34].freeze
    TEMPORARY_DESTINATIONS = [1, 15, 6, 14, 7, 27, 16, 4, 29, 18, 12, 13, 5, 2, 25, 32].freeze

    def run_question!
      @report.start(self.class.question_number, TABLE_NUMBERS)
      # TODO
      @report.complete(self.class.question_number)
    end
  end
end
