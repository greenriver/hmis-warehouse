###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'additional homeless population', shared_context: :metadata do
  describe 'Additional Homeless Populations:' do
    question = HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::QUESTION_NUMBER
    column_names = {
      'Emergency': 'B',
      'Transitional': 'C',
      'Safe Haven': 'D',
      'Outreach': 'E',
    }
    results = {
      'Adults with a Serious Mental Illness' => [158, 77, 1, 0],
      'Adults with a Substance Use Disorder' => [73, 65, 0, 0],
      'Adults with HIV/AIDS' => [1, 0, 0, 0],
      'Adult Survivors of Domestic Violence (optional)' => [44, 13, 0, 0],
    }

    results.each_with_index do |(category, data), row_index|
      # Account for header rows
      row_number = row_index + 2
      describe category do
        column_names.keys.each_with_index do |column, col_index|
          it column do
            cell_name = column_names[column] + row_number.to_s
            result = report_result.answer(question: question, cell: cell_name).summary
            expect(result).to eq(data[col_index])
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'additional homeless population', include_shared: true
end
