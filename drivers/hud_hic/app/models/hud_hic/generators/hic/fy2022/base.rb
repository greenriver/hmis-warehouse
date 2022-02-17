###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2022
  class Base < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util

    def run_question!
      @report.start(question_number, [question_number])
      universe

      header_row = destination_class.hmis_configuration(version: '2022').keys
      cell_columns = ('A'..header_row.count.to_csv_column).to_a
      universe.members.to_a.each_with_index do |row, row_index|
        header_row.each_with_index do |header, column_index|
          value = row.universe_membership[header]
          value = value.to_s(:db) if value.is_a?(Date) || value.is_a?(Time)
          cell_name = cell_columns[column_index] + (row_index + 1).to_s
          @report.answer(question: question_number, cell: cell_name).update(summary: value)
        end
      end

      metadata = {
        header_row: header_row,
        row_labels: [],
        first_column: 'A',
        last_column: header_row.count.to_csv_column,
        first_row: 2,
        last_row: universe.members.count + 1,
      }
      @report.answer(question: question_number).update(metadata: metadata)
    end

    private def universe
      add unless populated?

      @universe ||= @report.universe(self.class.question_number)
    end
  end
end
