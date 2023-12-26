###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

COLUMN_LABELS = ('A'..'Z').to_a.freeze

def goals(file_path:, question:, external_column_header:)
  csv_file = File.join(file_path, question + '.csv')
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

def compare_results(goal: nil, file_path:, question:, skip: [], external_column_header: false, external_row_label: false, detail_columns: [])
  goal ||= goals(file_path: file_path, question: question, external_column_header: external_column_header)

  aggregate_failures 'comparing cells' do
    results_metadata = report_result.answer(question: question).metadata
    expect(results_metadata['last_row']).to eq(goal.count), "expected #{results_metadata['last_row']} total rows, got #{goal.count} rows"
    (results_metadata['first_row'] .. results_metadata['last_row']).each do |row_number|
      (results_metadata['first_column'] .. results_metadata['last_column']).each do |column_name|
        cell_name = column_name + row_number.to_s
        next if cell_name.in?(skip)

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
