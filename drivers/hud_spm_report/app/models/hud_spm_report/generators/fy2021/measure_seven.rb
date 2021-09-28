###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Measure 7: Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing
module HudSpmReport::Generators::Fy2021
  class MeasureSeven < Base
    def self.question_number
      'Measure 7'.freeze
    end

    def self.tables
      [
        ['7a.1', :run_7a1, 'Change in exits to permanent housing destinations'],
        ['7b.1', :run_7b1, 'Change in exits to permanent housing destinations'],
        ['7b.2', :run_7b2, 'Change in exit to or retention of permanent housing'],
      ]
    end

    def self.table_descriptions
      {
        'Measure 7' => 'Successful Placement from Street Outreach and Successful Placement in or Retention of Permanent Housing',
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

    private def run_7a1(table_name)
      prepare_table table_name, {
        2 => 'Universe: Persons who exit Street Outreach',
        3 => 'Of persons above, those who exited to temporary & some institutional destinations',
        4 => 'Of the persons above, those who exited to permanent housing destinations',
        5 => '% Successful exits',
      }.freeze, CHANGE_TABLE_COLS

      # 4. Of the remaining leavers, report the distinct number of clients in
      # cell C2.
      c2 = universe.members.where(t[:m7a1_destination].not_eq(0))

      # 5. Of the remaining leavers, report the distinct number of clients
      # whose destination is “temporary or institutional” as indicated with a
      #  (values 1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32) in Appendix A in
      # cell C3.
      c3 = c2.where(t[:m7a1_destination].in([1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32]))

      # 6. Of the remaining leavers, report the distinct number of clients
      # whose destination is “permanent” as indicated with a X (values 26, 11,
      # 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34) in Appendix A in cell C4.
      c4 = c2.where(t[:m7a1_destination].in(PERMANENT_DESTINATIONS))

      # 7. Because each client is reported only once in cell C2 and no more
      # than once in cells C3 and C4, cell C5 is a simple formula indicated in
      # the table shell. The HMIS system should still generate this number to
      # 2 decimals places.
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

      # 4. Reference the destinations of the project exits against Appendix A (row headers) using the project type from which the exit occurred (column headers). Destinations indicated with an X (values 15, 6, 25, 24) cause leavers with those destinations to be completely excluded from the entire measure (all of column C).
      # 5. Of the remaining leavers, report the distinct number of clients in
      # cell C2.
      c2 = universe.members.where(t[:m7b1_destination].not_eq(nil))

      # 6. Of the remaining leavers, report the distinct number of clients
      # whose destination is “permanent” as indicated with a  (values 26, 11,
      # 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34) in Appendix A in cell C3.
      c3 = c2.where(t[:m7b1_destination].in(PERMANENT_DESTINATIONS))

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

    private def run_7b2(table_name)
      prepare_table table_name, {
        2 => 'Universe: Persons in all PH projects except PH-RRH who exited after moving into housing, or who moved into housing and remained in the PH project',
        3 => 'Of persons above, those who remained in applicable PH projects and those who exited to permanent housing destinations',
        4 => '% Successful exits/retention',
      }.freeze, CHANGE_TABLE_COLS

      # 6. Of the selected clients, report the distinct number of stayers and
      # leavers in cell C2.
      c2 = universe.members.where(t[:m7b2_destination].not_eq(nil))

      # 7. Of the selected clients, report the distinct number of leavers
      # whose destination is “permanent” as indicated with a  (values 26, 11,
      # 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34) in Appendix A + the
      # distinct number of stayers in cell C3.
      c3 = c2.where(t[:m7b2_destination].in(PERMANENT_DESTINATIONS_OR_STAYER))

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
