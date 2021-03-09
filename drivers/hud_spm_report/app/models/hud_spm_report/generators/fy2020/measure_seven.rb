###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 7: Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing
module HudSpmReport::Generators::Fy2020
  class MeasureSeven < Base
    def self.question_number
      'Measure 7'.freeze
    end

    def run_question!
      tables = [
        ['7a.1', :run_7a1, 'Change in exits to permanent housing destinations'],
        ['7b.1', :run_7b1, 'Change in exits to permanent housing destinations'],
        ['7b.2', :run_7b2, 'Change in exit to or retention of permanent housing'],
      ]
      @report.start(self.class.question_number, tables.map(&:first))

      universe

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_7a1(table_name)
      prepare_table table_name, {
        2 => 'Universe: Persons who exit Street Outreach',
        3 => 'Of persons above, those who exited to temporary & some institutional destinations',
        4 => 'Of the persons above, those who exited to permanent housing destinations',
        5 => '% Successful exits',
      }.freeze, CHANGE_TABLE_COLS

      c2 = universe.members
      c3 = c2.none
      c4 = c2.none

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', c4, c4.count],
        ['C5', [], report_precentage(c3.count + c4.count, c2.count)],
      ]
    end

    private def run_7b1(table_name)
      prepare_table table_name, {
        2 => 'Universe: Persons in ES, SH, TH, and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
        3 => 'Of the persons above, those who exited to permanent housing destinations',
        4 => '% Successful exits',
      }.freeze, CHANGE_TABLE_COLS

      c2 = universe.members
      c3 = c2.none

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', [], report_precentage(c3.count, c2.count)],
      ]
    end

    private def run_7b2(table_name)
      prepare_table table_name, {
        2 => 'Universe: Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
        3 => 'Of persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
        4 => '% Successful exits/retention',
      }.freeze, CHANGE_TABLE_COLS

      c2 = universe.members
      c3 = c2.none

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', [], report_precentage(c3.count, c2.count)],
      ]
    end
  end
end
