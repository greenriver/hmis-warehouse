###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://files.hudexchange.info/resources/documents/Notice-CPD-18-08-2019-HIC-PIT-Data-Collection-Notice.pdf
#
# https://files.hudexchange.info/resources/documents/2019-HIC-and-PIT-Count-Data-Submission-Guidance.pdf
#
#
# HIC Notes:
# *Sheltered Person Counts on the HIC and PIT Must Be Equal*
#
# Project Types (HIC):
#   ES, TH, SH, PH (PSH, RRH, Other PH (OPH) – consists of PH – Housing with Services (no disability required for entry) and PH – Housing Only)
#   OR numerically
#   1, 2, 3, 8, 9, 10, 13
#
# Items needed in HIC, not included in HMIS data
# * Victim Services Provider
# * Target Population A
#
# Inventory with a future "Inventory start date" should be considered (U) Under development

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
        first_row: 1,
        last_row: universe.members.count,
      }
      @report.answer(question: question_number).update(metadata: metadata)
    end

    private def universe
      add unless populated?

      @universe ||= @report.universe(self.class.question_number)
    end
  end
end
