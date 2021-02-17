###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class MeasureOne < Base
    def self.question_number
      'Measure 1'.freeze
    end

    TABLE_NUMBERS = ['1a', '1b'].freeze
    COLS = {
      'B' => 'Previous FY Universe (Persons)', # optional
      'C' => 'Current FY Universe (Persons)',
      'D' => 'Previous FY Average LOT Homeless', # optional
      'E' => 'Current FY Average LOT Homeless',
      'F' => 'Difference', # optional
      'G' => 'Previous FY Median LOT Homeless', # optional
      'H' => 'Current FY Median LOT Homeless',
      'I' => 'Difference', # optional
    }.freeze

    def run_question!
      @report.start(self.class.question_number, TABLE_NUMBERS)

      add_clients

      TABLE_NUMBERS.each do |table|
        msg = "run_#{table}"
        logger.debug msg
        send msg
      end
      @report.complete(self.class.question_number)
    end

    private def logger
      @report.logger
    end

    private def prepare_table(table_name, rows, cols)
      @report.answer(question: table_name).update(
        metadata: {
          header_row: [''] + cols.values,
          row_labels: rows.values,
          first_column: cols.keys.first,
          last_column: cols.keys.last,
          first_row: rows.keys.first,
          last_row: rows.keys.last,
        },
      )
    end

    # ['1a', 'A1', nil],
    # ['1a', 'C2', 1, 'persons in ES and SH'],
    # ['1a', 'E2', M1AE2_DAYS, 'mean LOT in ES and SH'],
    # ['1a', 'H2', 0, 'median LOT in ES and SH'],

    # ['1a', 'C3', 0, 'persons in ES, SH, and TH'],
    # ['1a', 'E3', 0, 'mean LOT in ES, SH, and TH'],
    # ['1a', 'H3', 0, 'median LOT in ES, SH, and TH'],

    # ['1b', 'A1', nil],
    # ['1b', 'C2', 1, 'persons in ES, SH, and PH'],
    # ['1b', 'E2', M1BE2_DAYS, 'mean LOT in ES, SH, and PH'],
    # ['1b', 'H2', 0, 'median LOT in ES, SH, and PH'],

    # ['1b', 'C3', 0, 'persons in ES, SH, TH, and PH'],
    # ['1b', 'E3', 0, 'mean LOT in ES, SH, TH, and PH'],
    # ['1b', 'H3', 0, 'median LOT in ES, SH, TH, and PH'],

    private def run_1a
      table_name = '1a'

      prepare_table table_name, {
        2 => 'Persons in ES and SH',
        3 => 'Persons in ES, SH, and TH',
      }, COLS

      t = HudSpmReport::Fy2020::SpmClient.arel_table
      [
        {
          cell: 'C2',
          clause: t[:m1a_es_sh_days].gt(0),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = universe.members.where(cell[:clause])
        answer.add_members(members) if members.any?
        answer.update(summary: members.count)
      end
    end

    private def run_1b
      table_name = '1b'
      rows = {
        2 => 'Persons in ES, SH, and PH',
        3 => 'Persons in ES, SH, TH, and PH',
      }
      prepare_table table_name, rows, COLS

      COLS.each do |_col, _clabel|
        rows.each do |row, _rlabel|
          # cell_ref = "#{col}#{row}"
          # answer = @report.answer(question: table_name, cell: cell_ref)
          # members = []
          # answer.add_members(members) if members.any?
          # answer.update(summary: members.count)
        end
      end
    end
  end
end
