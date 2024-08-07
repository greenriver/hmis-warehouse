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

  let(:hmis_csv_exporter) { double('HmisExportGenerator', run!: nil, content: 'abcd') }

  before do
    create(:hmis_data_source)
    allow(HmisExternalApis::AcHmis::Exporters::HmisExportFetcher).to receive(:new).and_return(hmis_csv_exporter)
  end

  it 'uploads clients' do
    subject.perform('clients_with_mci_ids_and_address')
    expect(subject.state).to eq(:success)
  end

  it 'uploads hmis csv' do
    expect(hmis_csv_exporter).to receive(:run!).with no_args
    subject.perform('hmis_csv_export')
  end

  it 'uploads 10-year full refresh hmis csv' do
    travel_to Time.local(2024, 1, 1) do
      today = Date.current
      expect(hmis_csv_exporter).to receive(:run!).with(start_date: today - 10.years)
      subject.perform('hmis_csv_export_full_refresh')
    end
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
    subject.perform('move_in_address_export')
    expect(subject.state).to eq(:success)
  end
end
