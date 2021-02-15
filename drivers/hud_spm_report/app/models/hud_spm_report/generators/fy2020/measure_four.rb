###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureFour < Base
    def self.question_number
      'Measure 4'.freeze
    end

    TABLE_NUMBERS = [
      '4.1',
      '4.2',
      '4.3',
      '4.4',
      '4.5',
      '4.6',
    ].freeze

    FUNDING_SOURCES = [2, 3, 4, 5, 43, 44].freeze

    def run_question!
      @report.start(self.class.question_number, TABLE_NUMBERS)
      # TODO
      @report.complete(self.class.question_number)
    end
  end
end
