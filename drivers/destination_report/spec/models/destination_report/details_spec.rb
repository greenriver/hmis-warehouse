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
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:headers) { report.client_headers }
  let(:restricted_values) do
    { 'Client ID' => restricted_destination_client.id, 'Personal ID' => 'ABC123', 'First Name' => 'Restricted', 'Last Name' => 'Client', 'DOB' => Date.new(1990, 1, 1), 'Sex' => 1 }
  end
  let(:open_values) do
    { 'Client ID' => open_destination_client.id, 'Personal ID' => 'XYZ789', 'First Name' => 'Open', 'Last Name' => 'Doe', 'DOB' => Date.new(1985, 6, 15), 'Sex' => 0 }
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  def configure_download_toggle(enabled)
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: enabled)
    GrdaWarehouse::Config.invalidate_cache
  end

  def row_for(headers, values)
    headers.map { |header| values.fetch(header, 0) }
  end

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  describe '#redact_pii_in_row' do
    it 'reads the client id from the first column' do
      expect(headers.first).to eq('Client ID')
    end

    context 'with mode: :browse' do
      it 'redacts the restricted client name and DOB, leaving other columns intact' do
        result = report.redact_pii_in_row(row_for(headers, restricted_values), headers: headers, user: user, mode: :browse)

        expect(result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('Last Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        expect(result[headers.index('Client ID')]).to eq(restricted_destination_client.id)
        expect(result[headers.index('Personal ID')]).to eq('ABC123')
        expect(result[headers.index('Sex')]).to eq(1)
      end

      it 'passes an unrestricted client row through unchanged' do
        row = row_for(headers, open_values)

        expect(report.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)).to eq(row)
      end
    end

    context 'with mode: :download' do
      it 'redacts an unrestricted client when include_pii_in_detail_downloads is off' do
        configure_download_toggle(false)

        result = report.redact_pii_in_row(row_for(headers, open_values), headers: headers, user: user, mode: :download)

        expect(result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('Last Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        expect(result[headers.index('Client ID')]).to eq(open_destination_client.id)
      end

      it 'passes an unrestricted client through and still redacts the restricted client when the toggle is on' do
        configure_download_toggle(true)
        open_row = row_for(headers, open_values)

        restricted_result = report.redact_pii_in_row(row_for(headers, restricted_values), headers: headers, user: user, mode: :download)

        expect(report.redact_pii_in_row(open_row, headers: headers, user: user, mode: :download)).to eq(open_row)
        expect(restricted_result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(restricted_result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      end
    end
  end
end
