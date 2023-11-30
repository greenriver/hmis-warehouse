###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
  class MeasureTwo < MeasureBase
    def self.question_number
      'Measure 2'.freeze
    end

    def self.table_descriptions
      {
        'Measure 2' => 'The Extent to which Persons Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months',
        '2a and 2b' => 'The Extent to which Persons Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months.',
      }.freeze
    end

    def run_question!
      tables = [
        ['2a and 2b', :run_2a],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
      'C' => 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
      'D' => 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
      'E' => 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
      'F' => 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
      'G' => 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
      'H' => 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
      'I' => 'Number of Returns in 2 Years',
      'J' => 'Percentage of Returns in 2 Years',
    }.freeze

    private def run_2a(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Exit was from SO',
          3 => 'Exit was from ES',
          4 => 'Exit was from TH',
          5 => 'Exit was from SH',
          6 => 'Exit was from PH',
          7 => 'TOTAL Returns to Homelessness',
        },
        COLUMNS,
      )
    end
  end
end
