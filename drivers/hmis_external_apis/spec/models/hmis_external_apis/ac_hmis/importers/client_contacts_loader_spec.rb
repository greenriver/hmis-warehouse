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
    csv_files = { 'ClientContacts.csv' => rows }
    expect {
      run_cde_import(csv_files: csv_files, clobber: true)
    }.to change(project.contact_points, :count).by(1)
  end
end
