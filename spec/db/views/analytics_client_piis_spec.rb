###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'analytics.client_piis view' do
  let(:client) { create(:hmis_hud_client_complete) }

  def pii_row_for(client)
    Hmis::Hud::Client.connection.select_all("SELECT * FROM analytics.client_piis WHERE id = #{client.id}").first
  end

  it 'shows real PII for a client with no restriction' do
    row = pii_row_for(client)

    expect(row).to include(
      'FirstName' => client.FirstName,
      'MiddleName' => client.MiddleName,
      'LastName' => client.LastName,
      'NameSuffix' => client.NameSuffix,
      'SSN' => client.SSN,
    )
  end

  it 'redacts name and SSN fields, but not DOB, for a client with an active restriction' do
    create(:hmis_restricted_record, restrictable: client)

    row = pii_row_for(client)

    expect(row).to include(
      'FirstName' => 'Redacted',
      'MiddleName' => 'Redacted',
      'LastName' => 'Redacted',
      'NameSuffix' => 'Redacted',
      'SSN' => 'Redacted',
    )
    expect(row['DOB']).to eq(client.DOB.to_fs(:db))
  end

  context 'when the restricted source client is merged into a destination client' do
    let(:destination_client) { create(:grda_warehouse_hud_client) }
    let(:sibling_source_client) { create(:hmis_hud_client_complete) }

    def link(source, destination, deleted_at: nil)
      GrdaWarehouse::WarehouseClient.create!(
        destination_id: destination.id,
        source_id: source.id,
        data_source_id: source.data_source_id,
        id_in_source: source.id.to_s,
        deleted_at: deleted_at,
      )
    end

    before do
      link(client, destination_client)
      link(sibling_source_client, destination_client)
      create(:hmis_restricted_record, restrictable: client)
    end

    it 'redacts the destination client' do
      row = pii_row_for(destination_client)

      expect(row).to include('FirstName' => 'Redacted', 'LastName' => 'Redacted', 'SSN' => 'Redacted')
      expect(row['DOB']).to eq(destination_client.DOB.to_fs(:db))
    end

    it 'redacts a sibling source client merged into the same destination' do
      row = pii_row_for(sibling_source_client)

      expect(row).to include('FirstName' => 'Redacted', 'LastName' => 'Redacted', 'SSN' => 'Redacted')
    end

    it 'does not redact a client whose only link to the restricted destination is soft-deleted' do
      unlinked_client = create(:hmis_hud_client_complete)
      link(unlinked_client, destination_client, deleted_at: Time.current)

      row = pii_row_for(unlinked_client)

      expect(row).to include('FirstName' => unlinked_client.FirstName, 'SSN' => unlinked_client.SSN)
    end

    it 'does not redact an unrelated destination client' do
      other_destination = create(:grda_warehouse_hud_client)
      link(create(:hmis_hud_client_complete), other_destination)

      row = pii_row_for(other_destination)

      expect(row).to include('FirstName' => other_destination.FirstName, 'SSN' => other_destination.SSN)
    end
  end

  it 'shows real PII again once an active restriction is soft-deleted' do
    restricted_record = create(:hmis_restricted_record, restrictable: client)
    restricted_record.destroy!

    row = pii_row_for(client)

    expect(row).to include(
      'FirstName' => client.FirstName,
      'MiddleName' => client.MiddleName,
      'LastName' => client.LastName,
      'NameSuffix' => client.NameSuffix,
      'SSN' => client.SSN,
    )
  end

  context 'with a retention mark on a source client' do
    let(:destination_client) { create(:grda_warehouse_hud_client) }

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: client.id, data_source_id: client.data_source_id, id_in_source: client.id.to_s)
      GrdaWarehouse::ClientRetentionMark.create!(client_id: client.id, marked_on: Date.current, last_activity_on: 10.years.ago.to_date, retention_years: 7)
    end

    it 'redacts the marked source' do
      expect(pii_row_for(client)['FirstName']).to eq('Redacted')
    end

    it 'redacts the destination the source is linked to' do
      expect(pii_row_for(destination_client)['FirstName']).to eq('Redacted')
    end

    it 'does not redact the destination once the link is soft-deleted' do
      GrdaWarehouse::WarehouseClient.where(source_id: client.id).update_all(deleted_at: Time.current)

      expect(pii_row_for(destination_client)['FirstName']).to eq(destination_client.FirstName)
    end
  end
end
