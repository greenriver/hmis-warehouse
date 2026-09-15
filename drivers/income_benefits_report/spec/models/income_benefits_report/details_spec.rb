###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IncomeBenefitsReport::Details, type: :model do
  let(:user) { create(:user) }
  let(:report) do
    IncomeBenefitsReport::Report.create!(
      user_id: user.id,
      report_date_range: Date.current.beginning_of_year..Date.current.end_of_year,
      comparison_date_range: 1.year.ago.beginning_of_year.to_date..1.year.ago.end_of_year.to_date,
    )
  end

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:restricted_values) do
    { 'Client ID' => restricted_destination_client.id, 'First Name' => 'Restricted', 'Last Name' => 'Client', 'DOB' => Date.new(1990, 1, 1), 'Age' => 34 }
  end
  let(:open_values) do
    { 'Client ID' => open_destination_client.id, 'First Name' => 'Open', 'Last Name' => 'Doe', 'DOB' => Date.new(1985, 6, 15), 'Age' => 39 }
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
      expect(report.header_for(nil).first).to eq('Client ID')
      expect(report.headers_for_export(nil).first).to eq('Client ID')
    end

    context 'with mode: :browse' do
      let(:headers) { report.header_for(nil) }

      it 'redacts the restricted client name and DOB, leaving other columns intact' do
        result = report.redact_pii_in_row(row_for(headers, restricted_values), headers: headers, user: user, mode: :browse)

        expect(result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('Last Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        expect(result[headers.index('Client ID')]).to eq(restricted_destination_client.id)
        expect(result[headers.index('Age')]).to eq(34)
      end

      it 'passes an unrestricted client row through unchanged' do
        row = row_for(headers, open_values)

        expect(report.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)).to eq(row)
      end
    end

    context 'with mode: :download and include_pii_in_detail_downloads on' do
      let(:headers) { report.headers_for_export(nil) }

      before { configure_download_toggle(true) }

      it 'keeps the PII columns in the export headers' do
        expect(headers).to eq(report.header_for(nil))
      end

      it 'redacts the restricted client and passes the unrestricted client through' do
        restricted_result = report.redact_pii_in_row(row_for(headers, restricted_values), headers: headers, user: user, mode: :download)
        open_row = row_for(headers, open_values)

        expect(restricted_result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
        expect(restricted_result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
        expect(report.redact_pii_in_row(open_row, headers: headers, user: user, mode: :download)).to eq(open_row)
      end
    end

    context 'with mode: :download and include_pii_in_detail_downloads off' do
      let(:headers) { report.headers_for_export(nil) }

      before { configure_download_toggle(false) }

      it 'omits the PII columns from the export headers' do
        expect(headers & ['First Name', 'Last Name', 'DOB']).to be_empty
        expect(headers).to include('Client ID', 'Age')
      end

      it 'returns the PII-free row unchanged' do
        row = row_for(headers, open_values)

        expect(report.redact_pii_in_row(row, headers: headers, user: user, mode: :download)).to eq(row)
      end
    end
  end
end
