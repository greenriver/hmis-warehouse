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
        '7a.1' => 'Change in exits to permanent housing destinations',
        '7b.1' => 'Change in exits to permanent housing destinations',
        '7b.2' => 'Change in exit to or retention of permanent housing',
      }.freeze
    end

    def run_question!
      tables = [
        ['7a.1', :run_7a_1],
        ['7b.1', :run_7b_1],
        ['7b.2', :run_7b_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_7a_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons who exit Street Outreach',
          3 => 'Of persons above, those who exited to temporary & some institutional destinations',
          4 => 'Of the persons above, those who exited to permanent housing destinations',
          5 => '% Successful exits',
        },
        COLUMNS,
      )
    end

    private def run_7b_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons in ES-EE, ES-NbN, SH, TH, and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
          3 => 'Of the persons above, those who exited to permanent housing destinations',
          4 => '% Successful exits',
        },
        COLUMNS,
      )
    end

    private def run_7b_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
          3 => 'Of persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
          4 => '% Successful exits/retention',
        },
        COLUMNS,
      )
    end
  end
end
