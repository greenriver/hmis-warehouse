###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestinationReport::Details, type: :model do
  let(:user) { create(:user) }
  let(:filter) { ::Filters::FilterBase.new(user: user, start: Date.current.beginning_of_year, end: Date.current.end_of_year) }
  let(:report) { DestinationReport::Report.new(filter) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  describe '#redact_pii_in_row' do
    it 'redacts the restricted client name and DOB in a client_headers-shaped row, leaving other columns intact' do
      headers = report.client_headers
      row = [restricted_destination_client.id, 'ABC123', 'Restricted', 'Client', Date.new(1990, 1, 1), 1] + Array.new(headers.size - 6, 0)

      result = report.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

      expect(result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(result[headers.index('Last Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(result[headers.index('Client ID')]).to eq(restricted_destination_client.id)
      expect(result[headers.index('Sex')]).to eq(1)
    end
  end
end
