###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaYyaReport::Report, 'unit tests' do
  let(:user) { create(:user) }
  let(:report) { described_class.new(user_id: user.id) }

  describe 'helper methods' do
    describe '#format_value' do
      it 'formats gender values using HudUtility2026' do
        expect(HudUtility2026).to receive(:gender).with(1).and_return('Man')
        result = report.format_value(1, 'gender')
        expect(result).to eq('Man')
      end

      it 'formats race values using format_race helper' do
        allow(report).to receive(:format_race).with(5).and_return('White')
        result = report.format_value(5, 'race')
        expect(result).to eq('White')
      end

      it 'formats arrays by joining with commas' do
        result = report.format_value(['item1', 'item2', 'item3'], 'other')
        expect(result).to eq('item1, item2, item3')
      end

      it 'formats boolean true as Yes' do
        result = report.format_value(true, 'other')
        expect(result).to eq('Yes')
      end

      it 'formats boolean false as No' do
        result = report.format_value(false, 'other')
        expect(result).to eq('No')
      end

      it 'returns other values as-is' do
        result = report.format_value('some string', 'other')
        expect(result).to eq('some string')

        result = report.format_value(42, 'other')
        expect(result).to eq(42)
      end
    end

    describe '#format_race' do
      before do
        allow(HudUtility2026).to receive(:race_known_ids).and_return([1, 2, 3, 4, 5, 7])
        allow(HudUtility2024).to receive(:race_id_to_field_name).and_return({ 5 => 'White' })
        allow(HudUtility2026).to receive(:race).with('White').and_return('White')
        allow(HudUtility2026).to receive(:race_nones).and_return({ 8 => 'Client doesn\'t know', 9 => 'Client prefers not to answer', 99 => 'Data not collected' })
        allow(HudUtility2026).to receive(:race_none).with(8).and_return('Client doesn\'t know')
      end

      it 'formats known race IDs using HudUtility2026' do
        result = report.send(:format_race, 5)
        expect(result).to eq('White')
      end

      it 'returns Multi-racial for code 10' do
        result = report.send(:format_race, 10)
        expect(result).to eq('Multi-racial')
      end

      it 'formats race none values' do
        result = report.send(:format_race, 8)
        expect(result).to eq('Client doesn\'t know')
      end

      it 'returns value as-is for unrecognized codes' do
        result = report.send(:format_race, 999)
        expect(result).to eq(999)
      end
    end

    describe '#lgbtq_query' do
      it 'creates query for LGBTQ+ identification' do
        result = report.send(:lgbtq_query)
        expect(result).to be_present
        expect(result).to respond_to(:to_sql)

        # Verify the SQL contains the expected LGBTQ+ conditions
        sql = result.to_sql
        expect(sql).to include('sexual_orientation')
        expect(sql).to include('gender')
      end
    end

    describe '#custodial_parent_query' do
      it 'returns SQL query for custodial parents' do
        result = report.send(:custodial_parent_query)
        expect(result).to include('jsonb_array_length(household_ages) > 1')
        expect(result).to include('18 > ANY (h_ages)')
        expect(result).to include('ma_yya_report_clients')
      end
    end

    describe '#find_previous_period_followup_client_ids' do
      it 'returns client IDs with subsequent current living situations' do
        client1 = { client_id: 1, subsequent_current_living_situations: [410, 435] }
        client2 = { client_id: 2, subsequent_current_living_situations: [] }
        client3 = { client_id: 3, subsequent_current_living_situations: [116] }

        result = report.send(:find_previous_period_followup_client_ids, [client1, client2, client3])
        expect(result).to contain_exactly(1, 3)
      end

      it 'returns empty array when no clients have followup situations' do
        client1 = { client_id: 1, subsequent_current_living_situations: [] }
        client2 = { client_id: 2, subsequent_current_living_situations: [] }

        result = report.send(:find_previous_period_followup_client_ids, [client1, client2])
        expect(result).to be_empty
      end
    end

    describe 'clause methods' do
      describe '#prevention_clause' do
        it 'returns condition for at-risk of homelessness' do
          result = report.send(:prevention_clause)
          expect(result).to be_present
          expect(result).to respond_to(:to_sql)
        end
      end

      describe '#homeless_clause' do
        it 'returns combined condition for homelessness' do
          result = report.send(:homeless_clause)
          expect(result).to be_present
          expect(result).to respond_to(:to_sql)
        end
      end

      describe '#prevention_remained_housed_clause' do
        it 'returns condition for prevention clients who remained housed' do
          result = report.send(:prevention_remained_housed_clause)
          expect(result).to be_present
          expect(result).to respond_to(:to_sql)
        end
      end

      describe '#became_housed_clause' do
        it 'returns condition for clients who became housed' do
          result = report.send(:became_housed_clause)
          expect(result).to be_present
          expect(result).to respond_to(:to_sql)
        end
      end
    end
  end

  describe 'public interface methods' do
    describe '#cell' do
      it 'finds report cell by name' do
        report_cells_relation = double('report_cells')
        allow(report).to receive(:report_cells).and_return(report_cells_relation)
        allow(report_cells_relation).to receive(:find_by).with(name: 'A1a').and_return('found_cell')

        result = report.cell('A1a')
        expect(result).to eq('found_cell')
      end
    end

    describe '#answer' do
      it 'returns summary from cell' do
        cell = OpenStruct.new(summary: 42)
        allow(report).to receive(:cell).with('A1a').and_return(cell)

        result = report.answer('A1a')
        expect(result).to eq(42)
      end

      it 'returns nil when cell not found' do
        allow(report).to receive(:cell).with('A1a').and_return(nil)

        result = report.answer('A1a')
        expect(result).to be_nil
      end
    end

    describe '#list_answer' do
      it 'returns joined structured data from cell' do
        cell = OpenStruct.new(structured_data: ['item1', 'item2', 'item3'])
        allow(report).to receive(:cell).with('F2d').and_return(cell)

        result = report.list_answer('F2d')
        expect(result).to eq('item1, item2, item3')
      end

      it 'returns nil when cell not found' do
        allow(report).to receive(:cell).with('F2d').and_return(nil)

        result = report.list_answer('F2d')
        expect(result).to be_nil
      end

      it 'returns nil when structured_data is nil' do
        cell = OpenStruct.new(structured_data: nil)
        allow(report).to receive(:cell).with('F2d').and_return(cell)

        result = report.list_answer('F2d')
        expect(result).to be_nil
      end
    end

    describe '#row_count' do
      it 'returns count from row_counts for known key' do
        allow(report).to receive(:row_counts).and_return({ 'A1' => 2, 'D1' => 7 })

        expect(report.row_count('A1')).to eq(2)
        expect(report.row_count('D1')).to eq(7)
      end
    end
  end
end
