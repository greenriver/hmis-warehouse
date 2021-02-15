###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureSix < Base
    def self.question_number
      'Measure 6'.freeze
    end

    TABLE_NUMBERS = [
      '6a.1 and 6b.1',
      '6c.1',
      '6c.2',
    ].freeze

    def run_question!
      @report.start(self.class.question_number, TABLE_NUMBERS)
      # TODO
      @report.complete(self.class.question_number)
    end
  end
end
