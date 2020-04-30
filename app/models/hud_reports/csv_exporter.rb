###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'csv'

module HudReports
  class CsvExporter
    def initialize(report, question)
      @report = report
      @question = question
      @metadata = report.answer(question: question).metadata
    end

    def csv_table
      CSV.generate(force_quotes: true) do |table|
        array_table.each { |row| table << row }
      end
    end

    def array_table
      @array_table ||= begin
        table = [ header_row ]

        row_names.each do |row_name|
          row = row_with_label(row_name)
          column_names.each do |column_name|
            row << @report.answer(question: @question, cell: "#{column_name}#{row_name}").summary || ''
          end
          table << row
        end

        table
      end
    end

    def csv_name
      "#{@question}.csv"
    end

    def header_row
      @metadata['header_row']
    end

    def row_names
      (@metadata['first_row']..@metadata['last_row'])
    end

    def row_with_label(row_name)
      label = @metadata['row_labels'][row_name.to_i - @metadata['first_row']] # Table rows are 1 based
      if label.present?
        [ label ]
      else
        []
      end
    end

    def column_names
      (@metadata['first_column']..@metadata['last_column'])
    end
  end
end