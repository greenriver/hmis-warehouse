###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureSeven < MeasureBase
    def self.question_number
      'Measure 7'.freeze
    end

    def self.table_descriptions
      {
        'Measure 7' => 'Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing',
      }.freeze
    end

    def run_question!
      # TODO
    end
  end
end
