###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::DataWarehouseUploadJob, type: :job do
  let!(:creds) do
    # port = ENV['CI'].present? ? 2222 : 22

    GrdaWarehouse::RemoteCredentials::Sftp.active.create!(
      slug: 'ac_data_warehouse_sftp_server',
      username: 'user',
      password: 'password',
      path: 'sftp',
      host: 'hmis-warehouse-sftp',
      port: 22,
    )
  end

  before { create(:hmis_data_source) }

  it 'uploads clients' do
    subject.perform('clients_with_mci_ids_and_address')
    expect(subject.state).to eq(:success)
  end

  it 'uploads hmis csv' do
    allow(HmisExternalApis::AcHmis::Exporters::HmisExportFetcher).to receive(:new).and_return(double('HmisExportGenerator', run!: nil, content: 'abcd'))
    subject.perform('hmis_csv_export')
  end

  it 'uploads project crosswalk' do
    cross_walk_fetcher_double = double(
      'ProjectCrossWalkFetcher',
      run!: nil,
      orgs_csv_stream: StringIO.new('Warehouse ID,HMIS Organization ID,Organization Name,Data Source,Date Updated'),
      projects_csv_stream: StringIO.new('Warehouse ID,HMIS ProjectID,Project Name,HMIS Organization ID,Organization Name,Data Source,Date Updated'),
    )

    allow(HmisExternalApis::AcHmis::Exporters::ProjectsCrossWalkFetcher).to receive(:new).and_return(cross_walk_fetcher_double)

    subject.perform('project_crosswalk')
    expect(subject.state).to eq(:success)
  end

  it 'uploads move in addresses' do
    subject.perform('move_in_addresses')
    expect(subject.state).to eq(:success)
  end
end
