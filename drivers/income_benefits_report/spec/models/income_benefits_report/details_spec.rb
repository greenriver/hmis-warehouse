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

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
  end

  describe '#redact_pii_in_row' do
    it 'redacts the restricted client name and DOB in a client_columns-shaped row, leaving other columns intact' do
      headers = ['Client ID', 'First Name', 'Last Name', 'DOB', 'Age', 'IncomeFromAnySource']
      row = [restricted_destination_client.id, 'Restricted', 'Client', Date.new(1990, 1, 1), 34, true]

      result = report.redact_pii_in_row(row, headers: headers, user: user, mode: :browse)

      expect(result[headers.index('First Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(result[headers.index('Last Name')]).to eq(GrdaWarehouse::PiiProvider::NAME_REDACTED)
      expect(result[headers.index('DOB')]).to eq(GrdaWarehouse::PiiProvider::REDACTED)
      expect(result[headers.index('Client ID')]).to eq(restricted_destination_client.id)
      expect(result[headers.index('IncomeFromAnySource')]).to eq(true)
    end
  end
end
