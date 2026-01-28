# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DatalabTestkit
  module TableComparisons
    module_function

    COLUMN_LABELS = ('A'..'Z').to_a.freeze

    def goals(file_path:, question:, csv_name:, external_column_header:)
      csv_file = File.join(file_path, csv_name || question + '.csv')
      data = CSV.read(csv_file)
      data = data[1..] if external_column_header # Drop the first line if the header is outside the table in the spec, but included in the goal file

      data
    end

    # Compare the contents of columns ignoring row order but preserving the column relationships.
    def compare_columns(goal:, question:, column_names:)
      results_metadata = report_result.answer(question: question).metadata
      column_names = Array.wrap(column_names)

      results_row = (results_metadata['first_row'] .. results_metadata['last_row']).map do |row_number|
        row = []
        column_names.each do |column_name|
          cell_name = column_name + row_number.to_s
          row << normalize(report_result.answer(question: question, cell: cell_name).summary)
        end
        row
      end

      goal_row = (results_metadata['first_row'] .. results_metadata['last_row']).map do |row_number|
        row = []
        column_names.each do |column_name|
          row << normalize(goal[row_number - 1][COLUMN_LABELS.find_index(column_name)])
        end
        row
      end

      aggregate_failures 'comparing column values' do
        expect(results_row.size).to eq(goal_row.size)
        expect(results_row).to match_array(goal_row)
      end
    end

    # Compares the results of a single question against expected goal data from a CSV file.
    # This method validates that the report output matches the expected values cell by cell.
    #
    # @param goal [Array<Array>] Optional pre-loaded goal data. If not provided, will load from CSV
    # @param file_path [String] Path to directory containing the goal CSV file
    # @param question [String] The report question identifier (e.g., 'Q7a', 'Q24')
    # @param skip [Array<String>] Cell names to skip during comparison (e.g., ['A1', 'B5'])
    # @param external_column_header [Boolean] True if CSV has header row that's not part of the table data
    # @param external_row_label [Boolean] True if CSV has row labels that are outside the actual table
    # @param csv_name [String] Custom CSV filename, defaults to "#{question}.csv"
    # @param detail_columns [Array<String>] Column names to include in error messages for debugging
    #
    # @example Basic usage
    #   compare_results(
    #     file_path: 'spec/fixtures/datalab_caper',
    #     question: 'Q7a'
    #   )
    #
    # @example Skip problematic cells
    #   compare_results(
    #     file_path: 'spec/fixtures/datalab_caper',
    #     question: 'Q24',
    #     skip: ['A1', 'B1'] # Skip cells that have known issues
    #   )
    #
    # @example Debug with detail columns (shows underlying data when assertions fail)
    #   compare_results(
    #     file_path: 'spec/fixtures/datalab_caper',
    #     question: 'Q7a',
    #     detail_columns: [:personal_id, :first_date_in_program, :last_date_in_program] # Shows these fields in error messages
    #   )
    #
    # @example Custom CSV filename
    #   compare_results(
    #     file_path: 'spec/fixtures/datalab_caper',
    #     question: 'Q7a',
    #     csv_name: 'custom_goals.csv' # Use different filename than default Q7a.csv
    #   )
    def compare_results(goal: nil, file_path:, question:, skip: [], external_column_header: false, external_row_label: false, csv_name: nil, detail_columns: [])
      goal ||= goals(file_path: file_path, question: question, csv_name: csv_name, external_column_header: external_column_header)

      aggregate_failures 'comparing cells' do
        results_metadata = report_result.answer(question: question).metadata
        expect(results_metadata['last_row']).to eq(goal.count), "expected #{results_metadata['last_row']} total rows, got #{goal.count} rows"
        (results_metadata['first_row'] .. results_metadata['last_row']).each do |row_number|
          (results_metadata['first_column'] .. results_metadata['last_column']).each do |column_name|
            cell_name = column_name + row_number.to_s
            next if cell_name.in?(skip) && ENV['TESTKIT_CHECK_ALL_TABLE_RESULTS'] != 'true'

            column_index = COLUMN_LABELS.find_index(column_name)
            column_index += 1 if external_row_label # Shift column index if the label is outside the table, but included in the goals
            raw_expected = goal[row_number - 1].try(:[], column_index)
            expected = normalize(raw_expected)
            raw_actual = report_result.answer(question: question, cell: cell_name).summary
            actual = normalize(raw_actual)
            error_message = "#{question} #{cell_name}: expected '#{expected}' (#{raw_expected}), got '#{actual}' (#{raw_actual})"
            if detail_columns.present?
              rows = report_result.answer(question: question, cell: cell_name).
                members.
                map(&:universe_membership).
                map { |m| detail_columns.map { |c| m[c] } }
              table = [detail_columns] + rows
              error_message += " details: #{table}"
            end
            expect(actual).to eq(expected), error_message
          end
        end
      end
    end

    # Validations are single rows from the validations defined in drivers/hud_apr/spec/models/fy2026/datalab_2_0_spec.rb
    # # Internal sum (note question for total is also Q7a)
    # { total: 'B10', source: { question: 'Q7a', expression: 'C2+C3+C4+C5', relevant_project_types: [13], operator: '==' }},
    # # Equality to constant
    # { total: 'B10', source: { question: 'Q7b', expression: 0, relevant_project_types: [13], operator: '==' }},
    # # Cross table comparison
    # { total: 'B10', source: { question: 'Q4', expression: 'B7', relevant_project_types: [13], operator: '==' }},
    # Non-equal comparison
    # { total: 'F2', source: { question: '', expression: '1', relevant_project_types: [0, 1, 2, 3, 4, 6, 8, 9, 7, 10, 11, 12, 13, 14], operator: '<=' }},
    # NOTE: project type filter is applied prior to calling check_sum
    def check_sum(validation:, question:)
      # ignore some checks we aren't sure of yet
      return if validation[:total].to_s.include?('+')

      raw_expected_total = report_result.answer(question: question, cell: validation[:total]).summary
      expected_total = normalize(raw_expected_total).to_f

      expression = validation[:source][:expression]
      source_question = validation[:source][:question]

      # For now, all expressions are sums of cells or constants
      # In the future, we may want to support other expressions
      source_cells = expression.split('+')

      value = 0
      source_cells.each do |cell_name|
        # Integer cells are stored as strings, so we need to check if the string is an integer
        if cell_name.to_i.to_s == cell_name
          value += normalize(cell_name).to_f
        else
          raw_actual = report_result.answer(question: source_question, cell: cell_name).summary
          value += normalize(raw_actual).to_f
        end
      end
      # puts validation.inspect
      # puts "Checking sum for #{question} #{validation[:total]}: expected '#{expected_total}', got '#{value}'"
      # flip the order of the expectation if the source_question is blank

      if source_question != question
        run_expectation(validation: validation, question: question, calculated_value: expected_total, expected_total: value)
      else
        run_expectation(validation: validation, question: question, calculated_value: value, expected_total: expected_total)
      end
    end

    def run_expectation(validation:, question:, calculated_value:, expected_total:)
      operator = validation[:source][:operator].to_s
      case operator
      when '==', ''
        expect(calculated_value).to eq(expected_total), "#{question} #{validation[:total]}: expected '#{expected_total}', got '#{calculated_value}'; #{validation.inspect}"
      when '>='
        expect(calculated_value).to be >= expected_total, "#{question} #{validation[:total]}: expected '#{expected_total}', got '#{calculated_value}'; #{validation.inspect}"
      when '<='
        expect(calculated_value).to be <= expected_total, "#{question} #{validation[:total]}: expected '#{expected_total}', got '#{calculated_value}'; #{validation.inspect}"
      else
        raise "Unknown operator: #{operator} for question #{question} #{validation.inspect}"
      end
    end

    def normalize(value)
      value = value&.to_s&.strip
      value = value[...-1] if percent?(value) # Remove percent signs
      return '0.0000' if value.blank? # Treat 0 and blank as the same for comparison

      value = value[1..] if money?(value) # Remove dollar signs
      value = value.to_f.round(2).to_s if float?(value) # only compare 2 significant digits
      value = '0' if normalize_zero?(value) # Treat all zeros as '0'

      format('%1.4f', value.to_f.round(4))
    end

    def normalize_zero?(value)
      /^[0\.]+$/.match?(value)
    end

    def percent?(value)
      /[0-9\.]+%$/.match(value)
    end

    def money?(value)
      /^\$-?[0-9\.]+$/.match?(value)
    end

    def float?(value)
      /^[0-9]+\.[0-9]+$/.match?(value)
    end
  end
end
