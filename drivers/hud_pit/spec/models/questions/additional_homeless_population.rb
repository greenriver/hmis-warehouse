###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'additional homeless population', shared_context: :metadata do
  describe 'Additional Homeless Populations:' do
    let(:question) { HudPit::Generators::Pit::Fy2024::AdditionalHomelessPopulations::QUESTION_NUMBER }
    let(:column_names) do
      {
        'Emergency': 'B',
        'Transitional': 'C',
        'Safe Haven': 'D',
        'Outreach': 'E',
      }
    end

    describe 'Adults with a Serious Mental Illness:' do
      let(:row_number) { 2 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(158)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(77)
      end
      it 'Safe Haven' do
        result = cell_result(question: question, cell_name: column_names[:'Safe Haven'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Outreach' do
        result = cell_result(question: question, cell_name: column_names[:Outreach] + row_number.to_s)
        expect(result).to eq(0)
      end
    end

    describe 'Adults with a Substance Use Disorder:' do
      let(:row_number) { 3 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(73)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(65)
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

    describe 'Adults with HIV/AIDS:' do
      let(:row_number) { 4 }
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

    describe 'Adult Survivors of Domestic Violence (optional):' do
      let(:row_number) { 5 }
      it 'Emergency' do
        result = cell_result(question: question, cell_name: column_names[:Emergency] + row_number.to_s)
        expect(result).to eq(44)
      end
      it 'Transitional' do
        result = cell_result(question: question, cell_name: column_names[:Transitional] + row_number.to_s)
        expect(result).to eq(13)
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
  rspec.include_context 'additional homeless population', include_shared: true
end

def cell_result(question:, cell_name:)
  report_result.answer(question: question, cell: cell_name).summary
end
