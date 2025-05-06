###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'adults', shared_context: :metadata do
  describe 'Adult Only (without children):' do
    question = HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER
    column_names = {
      'Emergency': 'B',
      'Transitional': 'C',
      'Safe Haven': 'D',
      'Outreach': 'E',
    }
    results = {
      'Total Number of Households' => [318, 97, 2, 1],
      'Total Number of Persons' => [326, 97, 2, 1],
      'Number of Persons (18 - 24)' => [22, 17, 0, 0],
      'Number of Persons (25 - 34)' => [59, 20, 0, 0],
      'Number of Persons (35 - 44)' => [78, 20, 0, 0],
      'Number of Persons (45 - 54)' => [73, 17, 0, 1],
      'Number of Persons (55 - 64)' => [74, 17, 1, 0],
      'Number of Persons (65 and older)' => [20, 6, 1, 0],
      # 'Woman (Girl, if child)' => [106, 49, 0, 0],
      # 'Man (Boy, if child)' => [216, 46, 2, 1],
      # 'Culturally Specific Identity (e.g., Two-Spirit)' => [0, 0, 0, 0],
      # 'Transgender' => [2, 0, 0, 0],
      # 'Non-Binary' => [1, 0, 0, 0],
      # 'Questioning' => [0, 0, 0, 0],
      # 'Different Identity' => [0, 0, 0, 0],
      # 'More Than One Gender' => [1, 1, 0, 0],
      'American Indian, Alaska Native, or Indigenous (only)' => [5, 1, 0, 0],
      'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o' => [3, 0, 0, 0],
      'Asian or Asian American (only)' => [1, 1, 0, 0],
      'Asian or Asian American & Hispanic/Latina/e/o' => [1, 0, 0, 0],
      'Black, African American, or African (only)' => [87, 17, 0, 0],
      'Black, African American, or African & Hispanic/Latina/e/o' => [1, 0, 0, 0],
      'Hispanic/Latina/e/o (only)' => [1, 2, 0, 0],
      'Middle Eastern or North African (only)' => [0, 0, 0, 0],
      'Middle Eastern or North African & Hispanic/Latina/e/o' => [0, 0, 0, 0],
      'Native Hawaiian or Pacific Islander (only)' => [1, 1, 0, 0],
      'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o' => [0, 0, 0, 0],
      'White (only)' => [201, 74, 2, 1],
      'White & Hispanic/Latina/e/o' => [10, 1, 0, 0],
      'Multi-Racial & Hispanic/Latina/e/o' => [1, 0, 0, 0],
      'Multi-Racial (all other)' => [13, 0, 0, 0],
      'Chronically Homeless: Total number of persons' => [59, 10, 0, 0],
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
