###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'projects', shared_context: :metadata do
  describe 'Projects:' do
    question = HudPit::Generators::Pit::Fy2025::Projects::QUESTION_NUMBER
    column_names = {
      'Project Name': 'B',
      'Client Count': 'C',
      'Household Count': 'D',
    }
    results = {
      'Organization H - TH' => ['Organization H - TH', 17, 17],
      'Organization Q - TH' => ['Organization Q - TH', 12, 7],
      'Organization M - ES' => ['Organization M - ES', 34, 27],
      'Organization I - ES' => ['Organization I - ES', 48, 41],
      'Organization G - ES' => ['Organization G - ES', 105, 32],
      'Organization B - TH' => ['Organization B - TH', 34, 13],
      'Organization S - ES' => ['Organization S - ES', 25, 10],
      'Organization M - TH' => ['Organization M - TH', 1, 1],
      'Organization C - TH' => ['Organization C - TH', 4, 4],
      'Organization D - TH' => ['Organization D - TH', 23, 11],
      'Organization D - TH - 2' => ['Organization D - TH - 2', 27, 16],
      'Organization O - TH' => ['Organization O - TH', 9, 9],
      'Organization F - ES' => ['Organization F - ES', 43, 37],
      'Organization E - TH' => ['Organization E - TH', 10, 9],
      'Organization M - ES - 2' => ['Organization M - ES - 2', 13, 10],
      'Organization A - ES' => ['Organization A - ES', 16, 16],
      'Organization N - TH:' => ['Organization N - TH', 4, 4],
      'Organization Z - ES' => ['Organization Z - ES', 10, 10],
      'Organization Z - TH' => ['Organization Z - TH', 4, 4],
      'Organization V - ES' => ['Organization V - ES', 2, 2],
      'Organization B - TH - 2' => ['Organization B - TH - 2', 3, 3],
      'Organization P - ES' => ['Organization P - ES', 2, 2],
      'Organization P - ES - 2' => ['Organization P - ES - 2', 21, 18],
      'Organization J - ES' => ['Organization J - ES', 10, 7],
      'Organization S - ES - 2' => ['Organization S - ES - 2', 19, 7],
      'Organization M - TH - 2' => ['Organization M - TH - 2', 4, 3],
      'Organization Q - ES' => ['Organization Q - ES', 68, 67],
      'Organization Z - TH - 2' => ['Organization Z - TH - 2', 7, 7],
      'Organization J - TH' => ['Organization J - TH', 1, 1],
      'Organization G - TH' => ['Organization G - TH', 9, 9],
      'Organization M - TH - 3' => ['Organization M - TH - 3', 2, 2],
      'Organization J - ES - 2' => ['Organization J - ES - 2', 2, 2],
      'Organization K - ES' => ['Organization K - ES', 9, 9],
      'Organization F - ES - 2' => ['Organization F - ES - 2', 2, 2],
      'Organization K - ES - 2' => ['Organization K - ES - 2', 27, 27],
      'Organization N - ES' => ['Organization N - ES', 1, 1],
      'Organization C - ES' => ['Organization C - ES', 10, 10],
      'Organization R - ES' => ['Organization R - ES', 13, 13],
      'Organization G - SH' => ['Organization G - SH', 2, 2],
      'Organization O - ES' => ['Organization O - ES', 23, 10],
      'Organization D - TH - 5' => ['Organization D - TH - 5', 4, 4],
      'Organization M - TH - 4' => ['Organization M - TH - 4', 5, 5],
      'Organization U - TH' => ['Organization U - TH', 2, 1],
      'Organization F - ES - 3' => ['Organization F - ES - 3', 12, 10],
      'Organization N - SO' => ['Organization N - SO', 1, 1],
      'Organization G - TH - 2' => ['Organization G - TH - 2', 2, 2],
      'Organization Q - ES - 2' => ['Organization Q - ES - 2', 1, 1],
      'Organization U - ES' => ['Organization U - ES', 9, 6],
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
  rspec.include_context 'adult and child', include_shared: true
end
