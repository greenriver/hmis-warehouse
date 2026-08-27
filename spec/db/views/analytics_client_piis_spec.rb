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
end
