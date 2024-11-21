###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'children', shared_context: :metadata do
  describe 'Child Only:' do
    let(:question) { HudPit::Generators::Pit::Fy2024::Children::QUESTION_NUMBER }
    let(:column_names) do
      {
        'Emergency': 'B',
        'Transitional': 'C',
        'Safe Haven': 'D',
        'Outreach': 'E',
      }
    end

    describe 'Total Number of Households:' do
      let(:row_number) { 2 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(3)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(7)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Total Number of Persons:' do
      let(:row_number) { 3 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(19)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(15)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Woman (Girl, if child):' do
      let(:row_number) { 4 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(8)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(8)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Man (Boy, if child):' do
      let(:row_number) { 5 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(11)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(7)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Culturally Specific Identity (e.g., Two-Spirit):' do
      let(:row_number) { 6 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Transgender:' do
      let(:row_number) { 7 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Non-Binary:' do
      let(:row_number) { 8 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Questioning:' do
      let(:row_number) { 9 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Different Identity:' do
      let(:row_number) { 10 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'More Than One Gender:' do
      let(:row_number) { 11 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'American Indian, Alaska Native, or Indigenous (only):' do
      let(:row_number) { 12 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o:' do
      let(:row_number) { 13 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Asian or Asian American (only):' do
      let(:row_number) { 14 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Asian or Asian American & Hispanic/Latina/e/o:' do
      let(:row_number) { 15 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Black, African American, or African (only):' do
      let(:row_number) { 16 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(10)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(6)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Black, African American, or African & Hispanic/Latina/e/o:' do
      let(:row_number) { 17 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Hispanic/Latina/e/o (only):' do
      let(:row_number) { 18 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Middle Eastern or North African (only):' do
      let(:row_number) { 19 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Middle Eastern or North African & Hispanic/Latina/e/o:' do
      let(:row_number) { 20 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Native Hawaiian or Pacific Islander (only):' do
      let(:row_number) { 21 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o:' do
      let(:row_number) { 22 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'White (only):' do
      let(:row_number) { 23 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(6)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(7)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'White & Hispanic/Latina/e/o:' do
      let(:row_number) { 24 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Multi-Racial & Hispanic/Latina/e/o:' do
      let(:row_number) { 25 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Multi-Racial (all other):' do
      let(:row_number) { 26 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Chronically Homeless: Total number of persons:' do
      let(:row_number) { 27 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(0)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'adult and child', include_shared: true
end

def cell_result(question:, cell_name:)
  report_result.answer(question: question, cell: cell_name).summary
end
