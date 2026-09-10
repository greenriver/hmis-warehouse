###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoreDemographicsReport::Details, type: :model do
  let(:user) { create(:user) }
  let(:report_date) { Date.current }
  let(:filter) do
    ::Filters::FilterBase.new(
      user: user,
      start: report_date.beginning_of_year,
      end: report_date.end_of_year,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
      enforce_one_year_range: false,
      require_service_during_range: true,
    )
  end
  let(:report) { CoreDemographicsReport::Core.new(filter) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    allow(user).to receive(:policy_for).and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
  end

  describe '#detail_column_display' do
    it 'redacts the restricted destination client and leaves the unrestricted one intact' do
      restricted_value = report.detail_column_display(header: 'First Name', column: 'Restricted', project_id: 1, client_id: restricted_destination_client.id)
      open_value = report.detail_column_display(header: 'First Name', column: 'Open', project_id: 1, client_id: open_destination_client.id)

      expect(restricted_value).to eq('Redacted')
      expect(open_value).to eq('Open')
    end
  end

  describe CoreDemographicsReport::DetailsColumn do
    it 'redacts the restricted destination client via #value and leaves the unrestricted one intact' do
      restricted_column = described_class.new(label: 'First Name', index: 0, user: user, project_id_index: 1, client_id_index: 2)
      open_column = described_class.new(label: 'First Name', index: 0, user: user, project_id_index: 1, client_id_index: 2)

      expect(restricted_column.value(['Restricted', 1, restricted_destination_client.id])).to eq('Redacted')
      expect(open_column.value(['Open', 1, open_destination_client.id])).to eq('Open')
    end
  end

  describe '#column_objects_for' do
    it 'derives client_id_index from the "Client ID" header position' do
      columns = report.column_objects_for(report.detail_hash.keys.first)
      expect(columns.first.client_id_index).to eq(0)
    end
  end
end
