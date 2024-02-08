###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureSix < MeasureBase
    def self.question_number
      'Measure 6'.freeze
    end

    def self.table_descriptions
      {
        'Measure 6' => "Homeless Prevention and Housing Placement of Persons Defined by Category 3 of HUD's Homeless Definition in CoC Program-funded Projects",
        '6a.1 and 6b.1' => 'Returns to ES, SH, TH, and PH projects after exits to permanent housing destinations within 6 and 12 months (and 24 months in a separate calculation)',
        '6c.1' => 'Change in exits to permanent housing destinations',
        '6c.2' => 'Change in exit to or retention of permanent housing',
      }.freeze
    end

    def run_question!
      tables = [
        ['6a.1 and 6b.1', :run_6a_1],
        ['6c.1', :run_6c_1],
        ['6c.2', :run_6c_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_6a_1(table_name)
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
        {
          'B' => 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
          'C' => 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
          'D' => 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
          'E' => 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
          'F' => 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
          'G' => 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
          'H' => 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
          'I' => 'Number of Returns in 2 Years',
          'J' => 'Percentage of Returns in 2 Years',
        },
      )
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_6c_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Cat. 3 Persons in SH, TH and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
          3 => 'Of the persons above, those who exited to permanent destinations',
          4 => '% Successful exits',
        },
        COLUMNS,
      )
    end

    private def run_6c_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Cat. 3 Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
          3 => 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations',
          4 => '% Successful exits/retention',
        },
        COLUMNS,
      )
    end
  end
end
