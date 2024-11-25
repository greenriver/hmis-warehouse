###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'additional homeless population', shared_context: :metadata do
  describe 'Additional Homeless Populations:' do
    question = HudPit::Generators::Pit::Fy2024::AdditionalHomelessPopulations::QUESTION_NUMBER
    column_names = {
      'Emergency': 'B',
      'Transitional': 'C',
      'Safe Haven': 'D',
      'Outreach': 'E',
    }
    results = {
      'Adults with a Serious Mental Illness' => {
        row_number: 2,
        values: [158, 77, 1, 0],
      },
      'Adults with a Substance Use Disorder' => {
        row_number: 3,
        values: [73, 65, 0, 0],
      },
      'Adults with HIV/AIDS' => {
        row_number: 4,
        values: [1, 0, 0, 0],
      },
      'Adult Survivors of Domestic Violence (optional)' => {
        row_number: 5,
        values: [44, 13, 0, 0],
      },
    }

    results.each do |category, (data)|
      describe category do
        column_names.keys.each_with_index do |column, index|
          it column do
            cell_name = column_names[column] + data[:row_number].to_s
            result = report_result.answer(question: question, cell: cell_name).summary
            expect(result).to eq(data[:values][index])
          end
        end
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'additional homeless population', include_shared: true
end
