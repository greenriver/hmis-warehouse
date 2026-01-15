###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::ReportClientBase, type: :model do
  # Use a concrete subclass for testing - HudApr::Fy2020::AprClient inherits from ReportClientBase
  # We create a bare instance to test the methods
  let(:client) do
    HudApr::Fy2020::AprClient.allocate
  end
  let(:pii_policy) { instance_double('PiiPolicy') }

  before do
    # Mock PiiProvider methods
    allow(GrdaWarehouse::PiiProvider).to receive(:viewable_ssn).and_return('***-**-3333')
    allow(GrdaWarehouse::PiiProvider).to receive(:viewable_dob).and_return('05/15/1990')
    allow(GrdaWarehouse::PiiProvider).to receive(:viewable_name).and_return('J.D.')
    allow(GrdaWarehouse::PiiProvider).to receive(:viewable_hiv_status).and_return('Unknown')
  end

  describe '#display_value' do
    context 'with simple scalar values' do
      it 'returns the value as-is for strings' do
        result = client.display_value('age', pii_policy: pii_policy, include_content_tag: false, cell_val: 'some string', calculate_cell: false)
        expect(result).to eq('some string')
      end

      it 'returns the value as-is for numbers' do
        result = client.display_value('age', pii_policy: pii_policy, include_content_tag: false, cell_val: 42, calculate_cell: false)
        expect(result).to eq(42)
      end

      it 'returns the value as-is for nil' do
        result = client.display_value('age', pii_policy: pii_policy, include_content_tag: false, cell_val: nil, calculate_cell: false)
        expect(result).to be_nil
      end
    end

    context 'with boolean values' do
      it 'formats true as yes/no' do
        result = client.display_value('some_flag', pii_policy: pii_policy, include_content_tag: false, cell_val: true, calculate_cell: false)
        expect(result).to be_present
      end

      it 'formats false as yes/no' do
        result = client.display_value('some_flag', pii_policy: pii_policy, include_content_tag: false, cell_val: false, calculate_cell: false)
        expect(result).to be_present
      end
    end

    context 'with array values' do
      it 'wraps arrays in a pre tag when include_content_tag is true' do
        array_value = [{ 'age' => 25 }, { 'age' => 30 }]
        result = client.display_value('household_members', pii_policy: pii_policy, include_content_tag: true, cell_val: array_value, calculate_cell: false)

        expect(result).to be_html_safe
        expect(result).to include('<pre>')
        expect(result).to include('</pre>')
        expect(result).to include('age')
      end

      it 'returns plain array when include_content_tag is false' do
        array_value = [{ 'age' => 25 }, { 'age' => 30 }]
        result = client.display_value('household_members', pii_policy: pii_policy, include_content_tag: false, cell_val: array_value, calculate_cell: false)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
      end

      it 'processes each array element through display_value' do
        array_value = [{ 'age' => 25 }]
        result = client.display_value('household_members', pii_policy: pii_policy, include_content_tag: true, cell_val: array_value, calculate_cell: false)

        # Verify it's wrapped in a single pre tag, not multiple
        expect(result.scan(/<pre/).length).to eq(1)
        expect(result.scan(/<\/pre/).length).to eq(1)
      end
    end

    context 'with hash values' do
      it 'wraps hashes in a pre tag when include_content_tag is true' do
        hash_value = { 'age' => 25, 'name' => 'John' }
        result = client.display_value('some_hash', pii_policy: pii_policy, include_content_tag: true, cell_val: hash_value, calculate_cell: false)

        expect(result).to be_html_safe
        expect(result).to include('<pre>')
        expect(result).to include('</pre>')
        expect(result).to include('age')
        expect(result).to include('name')
      end

      it 'returns plain hash when include_content_tag is false' do
        hash_value = { 'age' => 25, 'name' => 'John' }
        result = client.display_value('some_hash', pii_policy: pii_policy, include_content_tag: false, cell_val: hash_value, calculate_cell: false)

        expect(result).to be_a(Hash)
        expect(result['age']).to eq(25)
      end

      it 'processes each hash value through display_value' do
        hash_value = { 'age' => 25 }
        result = client.display_value('some_hash', pii_policy: pii_policy, include_content_tag: true, cell_val: hash_value, calculate_cell: false)

        # Verify it's wrapped in a single pre tag, not multiple
        expect(result.scan(/<pre/).length).to eq(1)
        expect(result.scan(/<\/pre/).length).to eq(1)
      end
    end

    context 'array of hashes - the household_members display fix' do
      it 'does not double-wrap in pre tags' do
        household_data = [
          { 'age' => 82, 'dob' => '1941-07-13' },
          { 'age' => 50, 'dob' => '1972-10-15' },
        ]

        result = client.display_value('household_members', pii_policy: pii_policy, include_content_tag: true, cell_val: household_data, calculate_cell: false)

        # Should have exactly one <pre> tag pair, not multiple (account for escaped HTML)
        pre_count = result.scan(/<pre/).count + result.scan(/&lt;pre/).count
        pre_close_count = result.scan(/<\/pre/).count + result.scan(/&lt;\/pre/).count
        expect([pre_count, pre_close_count]).to match_array([1, 1])
      end

      it 'produces valid JSON representation' do
        household_data = [
          { 'age' => 82 },
          { 'age' => 50 },
        ]

        result = client.display_value('household_members', pii_policy: pii_policy, include_content_tag: true, cell_val: household_data, calculate_cell: false)

        json_content = result.match(/<pre>(.*)<\/pre>/m)[1]
        # HTML unescape the content since content_tag escapes HTML entities
        json_content = CGI.unescape_html(json_content)
        parsed = JSON.parse(json_content)

        expect(parsed).to be_an(Array)
        expect(parsed.length).to eq(2)
        expect(parsed[0]['age']).to eq(82)
        expect(parsed[1]['age']).to eq(50)
      end
    end
  end
end
