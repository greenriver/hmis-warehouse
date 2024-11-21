###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'projects', shared_context: :metadata do
  describe 'Projects:' do
    let(:question) { HudPit::Generators::Pit::Fy2024::Projects::QUESTION_NUMBER }
    let(:column_names) do
      {
        'Project Name': 'B',
        'Client Count': 'C',
        'Household Count': 'D',
      }
    end

    describe 'Organization H - TH:' do
      let(:row_number) { 2 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization H - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(17)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(17)
      end
    end

    describe 'Organization Q - TH:' do
      let(:row_number) { 3 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Q - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(12)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(7)
      end
    end

    describe 'Organization M - ES:' do
      let(:row_number) { 4 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(34)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(27)
      end
    end

    describe 'Organization I - ES:' do
      let(:row_number) { 5 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization I - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(48)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(41)
      end
    end

    describe 'Organization G - ES:' do
      let(:row_number) { 6 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization G - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(105)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(32)
      end
    end

    describe 'Organization B - TH:' do
      let(:row_number) { 7 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization B - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(34)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(13)
      end
    end

    describe 'Organization S - ES:' do
      let(:row_number) { 8 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization S - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(25)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization M - TH:' do
      let(:row_number) { 9 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization C - TH:' do
      let(:row_number) { 10 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization C - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
    end

    describe 'Organization D - TH:' do
      let(:row_number) { 11 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization D - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(23)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(11)
      end
    end

    describe 'Organization D - TH - 2:' do
      let(:row_number) { 12 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization D - TH - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(27)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(16)
      end
    end

    describe 'Organization O - TH:' do
      let(:row_number) { 13 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization O - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
    end

    describe 'Organization F - ES:' do
      let(:row_number) { 14 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization F - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(43)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(37)
      end
    end

    describe 'Organization E - TH:' do
      let(:row_number) { 15 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization E - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
    end

    describe 'Organization M - ES - 2:' do
      let(:row_number) { 16 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(13)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization A - ES:' do
      let(:row_number) { 17 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization A - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(16)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(16)
      end
    end

    describe 'Organization N - TH:' do
      let(:row_number) { 18 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization N - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
    end

    describe 'Organization Z - ES:' do
      let(:row_number) { 19 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Z - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization Z - TH:' do
      let(:row_number) { 20 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Z - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
    end

    describe 'Organization V - ES:' do
      let(:row_number) { 21 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization V - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization B - TH - 2:' do
      let(:row_number) { 22 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization B - TH - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(3)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(3)
      end
    end

    describe 'Organization P - ES:' do
      let(:row_number) { 23 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization P - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization P - ES - 2:' do
      let(:row_number) { 24 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization P - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(21)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(18)
      end
    end

    describe 'Organization J - ES:' do
      let(:row_number) { 25 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization J - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(7)
      end
    end

    describe 'Organization S - ES - 2:' do
      let(:row_number) { 26 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization S - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(19)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(7)
      end
    end

    describe 'Organization M - TH - 2:' do
      let(:row_number) { 27 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - TH - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(3)
      end
    end

    describe 'Organization Q - ES:' do
      let(:row_number) { 28 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Q - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(68)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(67)
      end
    end

    describe 'Organization Z - TH - 2:' do
      let(:row_number) { 29 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Z - TH - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(7)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(7)
      end
    end

    describe 'Organization J - TH:' do
      let(:row_number) { 30 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization J - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization G - TH:' do
      let(:row_number) { 31 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization G - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
    end

    describe 'Organization M - TH - 3:' do
      let(:row_number) { 32 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - TH - 3')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization J - ES - 2:' do
      let(:row_number) { 33 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization J - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization K - ES:' do
      let(:row_number) { 34 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization K - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
    end

    describe 'Organization F - ES - 2:' do
      let(:row_number) { 35 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization F - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization K - ES - 2:' do
      let(:row_number) { 36 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization K - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(27)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(27)
      end
    end

    describe 'Organization N - ES:' do
      let(:row_number) { 37 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization N - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization C - ES:' do
      let(:row_number) { 38 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization C - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization R - ES:' do
      let(:row_number) { 39 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization R - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(13)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(13)
      end
    end

    describe 'Organization G - SH:' do
      let(:row_number) { 40 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization G - SH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization O - ES:' do
      let(:row_number) { 41 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization O - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(23)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization D - TH - 5:' do
      let(:row_number) { 42 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization D - TH - 5')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(4)
      end
    end

    describe 'Organization M - TH - 4:' do
      let(:row_number) { 43 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization M - TH - 4')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(5)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(5)
      end
    end

    describe 'Organization U - TH:' do
      let(:row_number) { 44 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization U - TH')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization F - ES - 3:' do
      let(:row_number) { 45 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization F - ES - 3')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(12)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(10)
      end
    end

    describe 'Organization N - SO:' do
      let(:row_number) { 46 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization N - SO')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization G - TH - 2:' do
      let(:row_number) { 47 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization G - TH - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(2)
      end
    end

    describe 'Organization Q - ES - 2:' do
      let(:row_number) { 48 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization Q - ES - 2')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(1)
      end
    end

    describe 'Organization U - ES:' do
      let(:row_number) { 49 }
      it 'Project Name' do
        result = cell_result(question: question, cell_name: column_names[:'Project Name'] + row_number.to_s)
        expect(result).to eq('Organization U - ES')
      end
      it 'Client Count' do
        result = cell_result(question: question, cell_name: column_names[:'Client Count'] + row_number.to_s)
        expect(result).to eq(9)
      end
      it 'Household Count' do
        result = cell_result(question: question, cell_name: column_names[:'Household Count'] + row_number.to_s)
        expect(result).to eq(6)
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
