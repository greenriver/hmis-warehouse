###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

RSpec.shared_context 'parenting youth', shared_context: :metadata do
  describe 'Parenting Youth Households:' do
    question = HudPit::Generators::Pit::Fy2025::ParentingYouth::QUESTION_NUMBER
    column_names = {
      'Emergency': 'B',
      'Transitional': 'C',
      'Outreach': 'D',
    }
    results = {
      'Total Number of Households' => [9, 4, 0],
      'Total Number of Persons' => [27, 8, 0],
      'Number of parenting youth (youth parents only)' => [9, 4, 0],
      'Total Children in Parenting Youth Households' => [16, 4, 0],
      'Number of parenting youth (under age 18)' => [0, 0, 0],
      'Children in households with parenting youth under age 18 (children under age 18 with parents under 18)' => [0, 0, 0],
      'Number of parenting youth (age 18 to 24)' => [9, 4, 0],
      'Children in households with parenting youth age 18 to 24 (children under age 18 with parents age 18 to 24)' => [16, 4, 0],
      # 'Woman (Girl, if child' => [9, 4, 0],
      # 'Man (Boy, if child)' => [0, 0, 0],
      # 'Culturally Specific Identity (e.g., Two-Spirit)' => [0, 0, 0],
      # 'Transgender' => [0, 0, 0],
      # 'Non-Binary' => [0, 0, 0],
      # 'Questioning' => [0, 0, 0],
      # 'Different Identity' => [0, 0, 0],
      # 'More Than One Gender' => [0, 0, 0],
      'American Indian, Alaska Native, or Indigenous (only)' => [0, 0, 0],
      'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o' => [0, 0, 0],
      'Asian or Asian American (only)' => [0, 0, 0],
      'Asian or Asian American & Hispanic/Latina/e/o' => [0, 0, 0],
      'Black, African American, or African (only)' => [3, 2, 0],
      'Black, African American, or African & Hispanic/Latina/e/o' => [0, 0, 0],
      'Hispanic/Latina/e/o (only)' => [0, 0, 0],
      'Middle Eastern or North African (only)' => [0, 0, 0],
      'Middle Eastern or North African & Hispanic/Latina/e/o' => [0, 0, 0],
      'Native Hawaiian or Pacific Islander (only)' => [0, 1, 0],
      'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o' => [0, 0, 0],
      'White (only)' => [4, 0, 0],
      'White & Hispanic/Latina/e/o' => [0, 1, 0],
      'Multi-Racial & Hispanic/Latina/e/o' => [2, 0, 0],
      'Multi-Racial (all other)' => [0, 0, 0],
      'Chronically Homeless: Total number of households' => [0, 0, 0],
      'Chronically Homeless: Total number of persons' => [1, 0, 0],
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
