COLUMN_LABELS = ('A'..'Z').to_a.freeze

def goals(file_path:, question:)
  csv_file = File.join(file_path, question + '.csv')
  CSV.read(csv_file)
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

def compare_results(goal: nil, file_path:, question:, skip: [])
  goal ||= goals(file_path: file_path, question: question)

  aggregate_failures 'comparing cells' do
    results_metadata = report_result.answer(question: question).metadata
    (results_metadata['first_row'] .. results_metadata['last_row']).each do |row_number|
      (results_metadata['first_column'] .. results_metadata['last_column']).each do |column_name|
        cell_name = column_name + row_number.to_s
        next if cell_name.in?(skip)

        column_index = COLUMN_LABELS.find_index(column_name)
        expected = normalize(goal[row_number - 1].try(:[], column_index))
        actual = normalize(report_result.answer(question: question, cell: cell_name).summary)

        expect(actual).to eq(expected), "#{cell_name}: expected '#{expected}', got '#{actual}'"
      end
    end
  end
end

def normalize(value)
  value = value&.to_s&.strip
  value = '0' if normalize_zero?(value) # Treat all zeros as '0'
  value = '0' if value.blank? # Treat 0 and blank as the same for comparison
  value = value[1..] if money?(value) # Remove dollar signs

  value
end

def normalize_zero?(value)
  /^[0\.]+$/.match?(value)
end

def money?(value)
  /^\$-?[0-9\.]+$/.match?(value)
end
