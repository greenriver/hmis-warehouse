###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'csv'

module HudReports
  class CsvExporter
    attr_accessor :report, :table, :metadata

    def initialize(report, table)
      @report = report
      @table = table
      @metadata = report.answer(question: table).metadata
    end

    def export(file_path)
      file = "#{file_path}/#{csv_name}"
      CSV.open(file, 'wb', force_quotes: true) do |table|
        as_array.each { |row| table << row }
      end
    end

    def as_array
      @as_array ||= begin
        table = answer_table

        row_names.each do |row_name|
          row = row_with_label(row_name)
          column_names.each do |column_name|
            answer = @report.answer(question: @table, cell: "#{column_name}#{row_name}").summary || ''
            answer = '0.0000' if answer == 'NaN'
            row << answer
          end
          table << row
        end

        table
      end
    end

    def csv_name
      "#{@table}.csv"
    end

    def answer_table
      return [] unless @metadata

      row = @metadata['header_row']
      if row.present?
        [row]
      else
        []
      end
    end

    def row_names
      return [] unless @metadata

      (@metadata['first_row']..@metadata['last_row'])
    end

    def row_with_label(row_name)
      label = @metadata['row_labels'][row_name.to_i - @metadata['first_row']] # Table rows are 1 based
      if label.present?
        [label]
      else
        []
      end
    end

    def column_names
      (@metadata['first_column']..@metadata['last_column'])
    end

    def display_column_names
      return [] unless @metadata

      ('A'..@metadata['last_column'])
    end
  end
end
