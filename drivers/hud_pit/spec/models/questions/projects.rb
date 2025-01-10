###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'projects', shared_context: :metadata do
  describe 'Projects:' do
    question = HudPit::Generators::Pit::Fy2024::Projects::QUESTION_NUMBER
    column_names = {
      'Project Name': 'B',
      'Client Count': 'C',
      'Household Count': 'D',
    }
    results = {
      'Organization H - TH' => {
        row_number: 2,
        values: ['Organization H - TH', 17, 17],
      },
      'Organization Q - TH' => {
        row_number: 3,
        values: ['Organization Q - TH', 12, 7],
      },
      'Organization M - ES' => {
        row_number: 4,
        values: ['Organization M - ES', 34, 27],
      },
      'Organization I - ES' => {
        row_number: 5,
        values: ['Organization I - ES', 48, 41],
      },
      'Organization G - ES' => {
        row_number: 6,
        values: ['Organization G - ES', 105, 32],
      },
      'Organization B - TH' => {
        row_number: 7,
        values: ['Organization B - TH', 34, 13],
      },
      'Organization S - ES' => {
        row_number: 8,
        values: ['Organization S - ES', 25, 10],
      },
      'Organization M - TH' => {
        row_number: 9,
        values: ['Organization M - TH', 1, 1],
      },
      'Organization C - TH' => {
        row_number: 10,
        values: ['Organization C - TH', 4, 4],
      },
      'Organization D - TH' => {
        row_number: 11,
        values: ['Organization D - TH', 23, 11],
      },
      'Organization D - TH - 2' => {
        row_number: 12,
        values: ['Organization D - TH - 2', 27, 16],
      },
      'Organization O - TH' => {
        row_number: 13,
        values: ['Organization O - TH', 9, 9],
      },
      'Organization F - ES' => {
        row_number: 14,
        values: ['Organization F - ES', 43, 37],
      },
      'Organization E - TH' => {
        row_number: 15,
        values: ['Organization E - TH', 10, 9],
      },
      'Organization M - ES - 2' => {
        row_number: 16,
        values: ['Organization M - ES - 2', 13, 10],
      },
      'Organization A - ES' => {
        row_number: 17,
        values: ['Organization A - ES', 16, 16],
      },
      'Organization N - TH:' => {
        row_number: 18,
        values: ['Organization N - TH', 4, 4],
      },
      'Organization Z - ES' => {
        row_number: 19,
        values: ['Organization Z - ES', 10, 10],
      },
      'Organization Z - TH' => {
        row_number: 20,
        values: ['Organization Z - TH', 4, 4],
      },
      'Organization V - ES' => {
        row_number: 21,
        values: ['Organization V - ES', 2, 2],
      },
      'Organization B - TH - 2' => {
        row_number: 22,
        values: ['Organization B - TH - 2', 3, 3],
      },
      'Organization P - ES' => {
        row_number: 23,
        values: ['Organization P - ES', 2, 2],
      },
      'Organization P - ES - 2' => {
        row_number: 24,
        values: ['Organization P - ES - 2', 21, 18],
      },
      'Organization J - ES' => {
        row_number: 25,
        values: ['Organization J - ES', 10, 7],
      },
      'Organization S - ES - 2' => {
        row_number: 26,
        values: ['Organization S - ES - 2', 19, 7],
      },
      'Organization M - TH - 2' => {
        row_number: 27,
        values: ['Organization M - TH - 2', 4, 3],
      },
      'Organization Q - ES' => {
        row_number: 28,
        values: ['Organization Q - ES', 68, 67],
      },
      'Organization Z - TH - 2' => {
        row_number: 29,
        values: ['Organization Z - TH - 2', 7, 7],
      },
      'Organization J - TH' => {
        row_number: 30,
        values: ['Organization J - TH', 1, 1],
      },
      'Organization G - TH' => {
        row_number: 31,
        values: ['Organization G - TH', 9, 9],
      },
      'Organization M - TH - 3' => {
        row_number: 32,
        values: ['Organization M - TH - 3', 2, 2],
      },
      'Organization J - ES - 2' => {
        row_number: 33,
        values: ['Organization J - ES - 2', 2, 2],
      },
      'Organization K - ES' => {
        row_number: 34,
        values: ['Organization K - ES', 9, 9],
      },
      'Organization F - ES - 2' => {
        row_number: 35,
        values: ['Organization F - ES - 2', 2, 2],
      },
      'Organization K - ES - 2' => {
        row_number: 36,
        values: ['Organization K - ES - 2', 27, 27],
      },
      'Organization N - ES' => {
        row_number: 37,
        values: ['Organization N - ES', 1, 1],
      },
      'Organization C - ES' => {
        row_number: 38,
        values: ['Organization C - ES', 10, 10],
      },
      'Organization R - ES' => {
        row_number: 39,
        values: ['Organization R - ES', 13, 13],
      },
      'Organization G - SH' => {
        row_number: 40,
        values: ['Organization G - SH', 2, 2],
      },
      'Organization O - ES' => {
        row_number: 41,
        values: ['Organization O - ES', 23, 10],
      },
      'Organization D - TH - 5' => {
        row_number: 42,
        values: ['Organization D - TH - 5', 4, 4],
      },
      'Organization M - TH - 4' => {
        row_number: 43,
        values: ['Organization M - TH - 4', 5, 5],
      },
      'Organization U - TH' => {
        row_number: 44,
        values: ['Organization U - TH', 2, 1],
      },
      'Organization F - ES - 3' => {
        row_number: 45,
        values: ['Organization F - ES - 3', 12, 10],
      },
      'Organization N - SO' => {
        row_number: 46,
        values: ['Organization N - SO', 1, 1],
      },
      'Organization G - TH - 2' => {
        row_number: 47,
        values: ['Organization G - TH - 2', 2, 2],
      },
      'Organization Q - ES - 2' => {
        row_number: 48,
        values: ['Organization Q - ES - 2', 1, 1],
      },
      'Organization U - ES' => {
        row_number: 49,
        values: ['Organization U - ES', 9, 6],
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
  rspec.include_context 'adult and child', include_shared: true
end
