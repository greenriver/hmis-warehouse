###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 6: Homeless Prevention and Housing Placement of Persons Defined by Category 3 of HUD’s Homeless Definition in CoC Program-funded Projects
module HudSpmReport::Generators::Fy2020
  class MeasureSix < Base
    def self.question_number
      'Measure 6'.freeze
    end

    def self.tables
      [
        ['6a.1 and 6b.1', :run_6a_and_6b, 'Returns to ES, SH, TH, and PH projects after exits to permanent housing destinations within 6 and 12 months (and 24 months in a separate calculation)'],
        ['6c.1', :run_6c1, 'Change in exits to permanent housing destinations'],
        ['6c.2', :run_6c2, 'Change in exit to or retention of permanent housing'],
      ]
    end

    def self.table_descriptions
      {
        'Measure 6' => 'Homeless Prevention and Housing Placement of Persons Defined by Category 3 of HUD\'s Homeless Definition in CoC Program-funded Projects',
      }.merge(
        tables.map do |table|
          [table.first, table.last]
        end.to_h,
      ).freeze
    end

    def run_question!
      @report.start(self.class.question_number, self.class.tables.map(&:first))

      self.class.tables.each do |name, msg, _title|
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

      # basically HudSpmReport::Generators::Fy2020::MeasureTwo with slightly differing scope

      {
        4 => TH,
        5 => SH,
        6 => PSH_ONLY + RRH,
        7 => TH + SH + PSH_ONLY + RRH,
      }.each do |row, project_types|
        scope = universe.members.where(t[:m6_exit_from_project_type].in(project_types))
        exited = scope
        n_exited = exited.count
        if n_exited.positive?
          reentered_0_5 = scope.where(t[:m6_reentry_days].between(1 .. 180))
          reentered_6_12 = scope.where(t[:m6_reentry_days].between(181 .. 365))
          reentered_13_24 = scope.where(t[:m6_reentry_days].between(366 .. 730))
          reentered = scope.where(t[:m6_reentry_days].between(1 .. 730))
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

    private def run_6c1(table_name)
      prepare_table table_name, {
        2 => 'Universe: Cat. 3 Persons in SH, TH and PH-RRH who exited, plus persons in other PH projects who exited without moving into housing',
        3 => 'Of the persons above, those who exited to permanent destinations',
        4 => '% Successful exits',
      }.freeze, CHANGE_TABLE_COLS

      # 5. Of the remaining leavers, report the distinct number of clients in
      # cell C2.
      c2 = universe.members.where(t[:m6c1_destination].not_eq(nil))

      # 6. Of the remaining leavers, report the distinct number of clients
      # whose destination is “permanent” as indicated with a  (values 26, 11,
      # 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34) in Appendix A in cell C3.
      c3 = c2.where(t[:m6c1_destination].in(PERMANENT_DESTINATIONS))

      # 7. Because each client is reported only once in cell C2 and no more
      # than once in cell C3, cell C4 is a simple formula indicated in the
      # table shell. The HMIS system should still generate these numbers to 2
      # decimals places.
      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', [], report_precentage(c3.count, c2.count)],
      ]
    end

    private def run_6c2(table_name)
      prepare_table table_name, {
        2 => 'Universe: Cat. 3 Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
        3 => 'Of persons above, count those who remained in PH-PSH projects and those who exited to permanent housing destinations',
        4 => '% Successful exits/retention',
      }.freeze, CHANGE_TABLE_COLS

      # 6. Of the selected clients, report the distinct number of stayers and
      # leavers in cell C2.
      c2 = universe.members.where(t[:m6c2_destination].not_eq(nil))

      # 7. Of the selected clients, report the distinct number of leavers
      # whose destination is “permanent” as indicated with a  (values 26, 11,
      # 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34) in Appendix A + the
      # distinct number of stayers in cell C3.
      c3 = c2.where(t[:m6c2_destination].in(PERMANENT_DESTINATIONS))

      # 8. Because each client is reported only once in cell C2 and no more
      # than once in cell C3, cell C4 is a simple formula indicated in the
      # table shell. The HMIS system should still generate these numbers to 2
      # decimals places.
      handle_clause_based_cells table_name, [
        ['C2', c2, c2.count],
        ['C3', c3, c3.count],
        ['C4', [], report_precentage(c3.count, c2.count)],
      ]
    end
  end
end
