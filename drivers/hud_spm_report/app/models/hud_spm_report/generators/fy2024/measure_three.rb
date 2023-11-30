###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
  class MeasureThree < MeasureBase
    def self.question_number
      'Measure 3'.freeze
    end

    def self.table_descriptions
      {
        'Measure 3' => 'Number of Persons Experiencing Homelessness',
        '3.1' => 'Change in PIT counts of sheltered and unsheltered persons experiencing homelessness',
        '3.2' => 'Change in annual counts of persons experiencing sheltered homelessness in HMIS',
      }.freeze
    end

    def run_question!
      tables = [
        ['3.1', :run_3_1],
        ['3.2', :run_3_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_3_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Total PIT Count of sheltered and unsheltered persons',
          3 => 'Emergency Shelter Total',
          4 => 'Safe Haven Total',
          5 => 'Transitional Housing Total',
          6 => 'Total Sheltered Count',
          7 => 'Unsheltered Count',
        },
        {
          'B' => 'Previous FY PIT Count',
          'C' => 'Current FY PIT Count',
          'D' => 'Difference',
        },
      )
    end

    private def run_3_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Unduplicated Total sheltered persons',
          3 => 'Emergency Shelter Total',
          4 => 'Safe Haven Total',
          5 => 'Transitional Housing Total',
        },
        {
          'B' => 'Previous FY',
          'C' => 'Current FY',
          'D' => 'Difference',
        },
      )
    end
  end
end
