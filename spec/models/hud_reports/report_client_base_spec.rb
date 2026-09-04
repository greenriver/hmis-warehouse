###
# Copyright Green River Data Group, Inc.
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

  describe '.search_clients' do
    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:restricted_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restrictedfirst', last_name: 'Restrictedlast') }
    let!(:open_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Openfirst', last_name: 'Openlast') }
    let!(:restricted_apr_client) do
      create(
        :hud_report_apr_client, first_name: restricted_client.first_name, last_name: restricted_client.last_name,
                                personal_id: restricted_client.personal_id, client_id: restricted_client.id,
                                destination_client_id: restricted_client.id
      )
    end
    let!(:open_apr_client) do
      create(
        :hud_report_apr_client, first_name: open_client.first_name, last_name: open_client.last_name,
                                personal_id: open_client.personal_id, client_id: open_client.id,
                                destination_client_id: open_client.id
      )
    end

    before { restricted_client.mark_as_restricted!(user: hmis_user) }

    it 'excludes a restricted client from a name search' do
      results = HudApr::Fy2020::AprClient.search_clients(HudApr::Fy2020::AprClient.all, 'Restrictedlast')
      expect(results).not_to include(restricted_apr_client)
    end

    it 'still returns a non-restricted client from a name search' do
      results = HudApr::Fy2020::AprClient.search_clients(HudApr::Fy2020::AprClient.all, 'Openlast')
      expect(results).to include(open_apr_client)
    end

    it 'still returns a restricted client from an exact personal_id search' do
      results = HudApr::Fy2020::AprClient.search_clients(HudApr::Fy2020::AprClient.all, restricted_apr_client.personal_id)
      expect(results).to include(restricted_apr_client)
    end

    it 'still returns a restricted client from an exact destination_client_id search' do
      results = HudApr::Fy2020::AprClient.search_clients(HudApr::Fy2020::AprClient.all, restricted_apr_client.destination_client_id.to_s)
      expect(results).to include(restricted_apr_client)
    end

    it 'does not filter models that do not declare pii_search_columns' do
      expect(HudSpmReport::Fy2020::SpmClient.pii_search_columns).to eq([])
    end
  end

  describe '#destination_client_id_for_pii' do
    it 'returns destination_client_id when the column exists' do
      apr_client = HudApr::Fy2020::AprClient.new(destination_client_id: 42)
      expect(apr_client.destination_client_id_for_pii).to eq(42)
    end

    it 'falls back to client_id when there is no destination_client_id column' do
      spm_client = HudSpmReport::Fy2020::SpmClient.new(client_id: 99)
      expect(spm_client.destination_client_id_for_pii).to eq(99)
    end

    it 'returns nil when the model has neither column' do
      expect(HmisDataQualityTool::Inventory.new.destination_client_id_for_pii).to be_nil
    end

    it 'resolves without raising for every item class the DQT report can produce' do
      item_classes = HmisDataQualityTool::Report.new.send(:result_groups).values.flat_map(&:values).uniq
      item_classes.each do |klass|
        expect { klass.new.destination_client_id_for_pii }.not_to raise_error
      end
    end
  end
end
