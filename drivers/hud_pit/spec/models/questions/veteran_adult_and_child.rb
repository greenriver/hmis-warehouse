###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'veteran adult and child', shared_context: :metadata do
  describe 'Adult & Child Veteran Households (at least one adult and one child):' do
    question = HudPit::Generators::Pit::Fy2024::VeteranAdultAndChild::QUESTION_NUMBER
    column_names = {
      'Emergency': 'B',
      'Transitional': 'C',
      'Outreach': 'D',
    }
    results = {
      'Total Number of Households' => {
        row_number: 2,
        values: [0, 1, 0],
      },
      'Total Number of Persons' => {
        row_number: 3,
        values: [0, 2, 0],
      },
      'Total Number of Veterans' => {
        row_number: 4,
        values: [0, 1, 0],
      },
      'Woman (Girl, if child)' => {
        row_number: 5,
        values: [0, 1, 0],
      },
      'Man (Boy, if child)' => {
        row_number: 6,
        values: [0, 0, 0],
      },
      'Culturally Specific Identity (e.g., Two-Spirit)' => {
        row_number: 7,
        values: [0, 0, 0],
      },
      'Transgender' => {
        row_number: 8,
        values: [0, 0, 0],
      },
      'Non-Binary' => {
        row_number: 9,
        values: [0, 0, 0],
      },
      'Questioning' => {
        row_number: 10,
        values: [0, 0, 0],
      },
      'Different Identity' => {
        row_number: 11,
        values: [0, 0, 0],
      },
      'More Than One Gender' => {
        row_number: 12,
        values: [0, 0, 0],
      },
      'American Indian, Alaska Native, or Indigenous (only)' => {
        row_number: 13,
        values: [0, 0, 0],
      },
      'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o' => {
        row_number: 14,
        values: [0, 0, 0],
      },
      'Asian or Asian American (only)' => {
        row_number: 15,
        values: [0, 0, 0],
      },
      'Asian or Asian American & Hispanic/Latina/e/o' => {
        row_number: 16,
        values: [0, 0, 0],
      },
      'Black, African American, or African (only)' => {
        row_number: 17,
        values: [0, 0, 0],
      },
      'Black, African American, or African & Hispanic/Latina/e/o' => {
        row_number: 18,
        values: [0, 0, 0],
      },
      'Hispanic/Latina/e/o (only)' => {
        row_number: 19,
        values: [0, 0, 0],
      },
      'Middle Eastern or North African (only)' => {
        row_number: 20,
        values: [0, 0, 0],
      },
      'Middle Eastern or North African & Hispanic/Latina/e/o' => {
        row_number: 21,
        values: [0, 0, 0],
      },
      'Native Hawaiian or Pacific Islander (only)' => {
        row_number: 22,
        values: [0, 0, 0],
      },
      'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o' => {
        row_number: 23,
        values: [0, 0, 0],
      },
      'White (only)' => {
        row_number: 24,
        values: [0, 2, 0],
      },
      'White & Hispanic/Latina/e/o' => {
        row_number: 25,
        values: [0, 0, 0],
      },
      'Multi-Racial & Hispanic/Latina/e/o' => {
        row_number: 26,
        values: [0, 0, 0],
      },
      'Multi-Racial (all other)' => {
        row_number: 27,
        values: [0, 0, 0],
      },
      'Chronically Homeless: Total number of households' => {
        row_number: 28,
        values: [0, 0, 0],
      },
      'Chronically Homeless: Total number of persons' => {
        row_number: 29,
        values: [0, 0, 0],
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
