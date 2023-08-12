###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        'VALUE' => '8675309',
        'NOTES' => 'test notes',
        'UserID' => '',
        'DateCreated' => '2014-10-07 16:10:39',
        'DateUpdated' => '2014-10-07 16:10:39',
      },
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'ClientContacts.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(client.contact_points.size).to eq(1)
  end
end
