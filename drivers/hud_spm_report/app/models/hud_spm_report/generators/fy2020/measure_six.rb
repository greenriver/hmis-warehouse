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

    def run_question!
      tables = [
        ['6a.1 and 6b.1', :run_6a_and_6b, 'Returns to ES, SH, TH, and PH projects after exits to permanent housing destinations within 6 and 12 months (and 24 months in a separate calculation)'],
        ['6c.1', :run_6c1, 'Change in exits to permanent housing destinations'],
        ['6c.2', :run_6c2, 'Change in exit to or retention of permanent housing'],
      ]
      @report.start(self.class.question_number, tables.map(&:first))

      universe

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_6a_and_6b(table_name)
      prepare_table table_name, {
        2 => 'Exit was from SO',
        3 => 'Exit was from ES',
        4 => 'Exit was from TH',
        5 => 'Exit was from SH',
        6 => 'Exit was from PH',
        7 => 'TOTAL Returns to Homeless',
      }.freeze, {
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

      {
        4 => TH,
        5 => SH,
        6 => PH,
        7 => SO + ES + TH + SH + PH,
      }.each do |row, project_types|
        scope = universe.members.where(t[:m2_exit_from_project_type].in(project_types))
        exited = scope
        n_exited = exited.count
        if n_exited.positive?
          reentered_0_5 = scope.where(t[:m2_reentry_days].between(1 .. 180))
          reentered_6_12 = scope.where(t[:m2_reentry_days].between(181 .. 365))
          reentered_13_24 = scope.where(t[:m2_reentry_days].between(366 .. 730))
          reentered = scope.where(t[:m2_reentry_days].between(1 .. 730))
        else
          reentered_0_5 = scope.none
          reentered_6_12 = scope.none
          reentered_13_24 = scope.none
          reentered = scope.none
        end

        handle_clause_based_cells table_name, [
          ["B#{row}", exited, exited.count],
          ["C#{row}", reentered_0_5, reentered_0_5.count],
          ["D#{row}", [], report_precentage(reentered_0_5.count, n_exited)],
          ["E#{row}", reentered_6_12, reentered_6_12.count],
          ["F#{row}", [], report_precentage(reentered_6_12.count, n_exited)],
          ["G#{row}", reentered_13_24, reentered_13_24.count],
          ["H#{row}", [], report_precentage(reentered_13_24.count, n_exited)],
          ["I#{row}", reentered, reentered.count],
          ["J#{row}", [], report_precentage(reentered.count, n_exited)],
        ]
      end
    end

    DIFF_COLS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    DIFF_ROWS = {
      2 => 'Universe: Cat. 3 Persons in SH, TH and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
      3 => 'Of the persons above, those who exited to permanent destinations',
      4 => '% Successful exits',
    }.freeze

    private def run_6c1(table_name)
      prepare_table table_name, DIFF_ROWS, DIFF_COLS

      c2 = universe.members
      c3 = c2.none

      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', [], report_precentage(c3.count, c2.count)],
      ]
    end

    private def run_6c2(table_name)
      prepare_table table_name, DIFF_ROWS, DIFF_COLS

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
