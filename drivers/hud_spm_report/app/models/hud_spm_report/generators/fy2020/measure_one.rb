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

    private def run_1a
      table_name = '1a'

      prepare_table table_name, {
        2 => 'Persons in ES and SH',
        3 => 'Persons in ES, SH, and TH',
      }, COLS

      [
        {
          cell: 'B2',
          clause: '1=0',
        },
        {
          cell: 'C2',
          clause: '1=0',
        },
        {
          cell: 'D2',
          clause: '1=0',
        },
        {
          cell: 'E2',
          clause: '1=0',
        },
        {
          cell: 'F2',
          clause: '1=0',
        },
        {
          cell: 'G2',
          clause: '1=0',
        },
        {
          cell: 'H2',
          clause: '1=0',
        },
        {
          cell: 'I2',
          clause: '1=0',
        },
        {
          cell: 'A3',
          clause: '1=0',
        },
        {
          cell: 'B3',
          clause: '1=0',
        },
        {
          cell: 'C3',
          clause: '1=0',
        },
        {
          cell: 'D3',
          clause: '1=0',
        },
        {
          cell: 'E3',
          clause: '1=0',
        },
        {
          cell: 'F3',
          clause: '1=0',
        },
        {
          cell: 'G3',
          clause: '1=0',
        },
        {
          cell: 'H3',
          clause: '1=0',
        },
        {
          cell: 'I3',
          clause: '1=0',
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        # members = universe.members.where(cell[:clause])
        members = []
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

      COLS.each do |col, _clabel|
        rows.each do |row, _rlabel|
          cell = "#{col}#{row}"
          answer = @report.answer(question: table_name, cell: cell)
          # members = universe.members.where(cell[:clause])
          members = []
          answer.add_members(members) if members.any?
          answer.update(summary: members.count)
        end
      end
    end
  end
end
