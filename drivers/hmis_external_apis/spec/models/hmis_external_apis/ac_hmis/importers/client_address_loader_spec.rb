###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::Loaders::ClientAddressLoader, type: :model do
  include AcHmisLoaderHelpers

  let(:ds) { create(:hmis_data_source) }
  let(:client) { create(:hmis_hud_client, data_source: ds) }
  let(:rows) do
    [
      {
        'PersonalID' => client.PersonalID,
        'use' => 'Home',
        'line1' => '1234 Main st',
        'line2' => '',
        'city' => 'Brattleboro',
        'state' => 'Vermont',
        'county' => 'Windham',
        'zip' => '05301',
        'Zipextension' => '',
        'UserID' => '',
        'DateCreated' => '2014-10-07 16:10:39',
        'DateUpdated' => '2014-10-07 16:10:39',
      },
    ]
  end

  it 'imports rows' do
    with_csv_files({ 'ClientAddress.csv' => rows }) do |dir|
      described_class.perform(reader: csv_reader(dir))
    end
    expect(client.addresses.size).to eq(1)
  end
end
