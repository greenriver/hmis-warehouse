###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Length of Time Persons Remain Homeless
module HudSpmReport::Generators::Fy2023
  class MeasureOne < MeasureBase
    def self.question_number
      'Measure 1'.freeze
    end

    def self.table_descriptions
      {
        'Measure 1' => 'Length of Time Persons Experience Homelessness',
      }.freeze
    end

    def run_question!
      # TODO
    end
  end
end
