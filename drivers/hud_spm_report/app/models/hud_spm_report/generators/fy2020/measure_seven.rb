###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureSeven < Base
    def self.question_number
      'Measure 7'.freeze
    end

    TABLE_NUMBERS = [
      '7a.1',
      '7b.1',
      '7b.2',
    ].freeze

    def run_question!
      @report.start(self.class.question_number, TABLE_NUMBERS)
      # TODO
      @report.complete(self.class.question_number)
    end
  end
end
