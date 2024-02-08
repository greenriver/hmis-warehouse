###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ClientContactsLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:rows) do
    [
      {
        'PersonalID' => client.PersonalID,
        'PHONE_TYPE' => 'Home',
        'SYSTM' => 'PHONE',
        'VALUE' => '(123) 867-5309',
        'NOTES' => 'test notes',
        'UserID' => '',
        'DateCreated' => '7/1/2020 16:10',
        'DateUpdated' => '7/1/2020 16:10',
      },
      {
        'PersonalID' => client.PersonalID,
        'PHONE_TYPE' => 'EMAIL',
        'SYSTM' => 'EMAIL',
        'VALUE' => 'foo123@gmail.com',
        'NOTES' => '',
        'UserID' => '',
        'DateCreated' => '7/1/2020 16:10',
        'DateUpdated' => '7/1/2020 16:10',
      },
    ]
  end

  it 'imports rows' do
    csv_files = { 'ClientContacts.csv' => rows }
    expect do
      run_cde_import(csv_files: csv_files, clobber: true)
    end.to change(client.contact_points, :count).by(2)

    expect(client.contact_points.phones.count).to eq(1)
    expect(client.contact_points.phones.first.value).to eq('1238675309')
    expect(client.contact_points.emails.count).to eq(1)
    expect(client.contact_points.emails.first.value).to eq('foo123@gmail.com')
  end
end
