###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::UploadClientsJob, type: :job do
  let!(:creds) do
    port = ENV['CI'].present? ? 2222 : 22

    GrdaWarehouse::RemoteCredentials::Sftp.create!(
      slug: 'ac_hmis_client_export',
      username: 'user',
      password: 'password',
      path: 'sftp',
      host: 'hmis-warehouse-sftp',
      port: port,
    )
  end

  it 'uploads clients' do
    create(:hmis_data_source)
    subject.perform
    expect(subject.state).to eq(:success)
  end
end
