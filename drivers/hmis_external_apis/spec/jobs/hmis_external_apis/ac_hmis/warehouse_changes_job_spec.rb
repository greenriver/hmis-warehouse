###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::WarehouseChangesJob, type: :job do
  let(:user) { create(:user) }
  let(:job) { HmisExternalApis::AcHmis::WarehouseChangesJob.new }
  let(:data_source) { create(:hmis_data_source, name: 'HMIS', authoritative: true) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
  let(:default_record) do
    {
      'srcSysKey' => 123,
      'srcSysDesc' => 'Master Client Index (MCI)',
      'clientId' => client.warehouse_id.to_s,
      'mciUniqId' => 1_000_119_810,
      'firstName' => 'first',
      'middleName' => nil,
      'lastName' => 'last',
      'dob' => '1980-01-01T00:00:00',
      'dod' => nil,
      'ssn' => 'XXXXX1111',
      'isCurrent' => 'Y',
      'effDate' => '2018-12-18T07:25:42',
      'mciUniqIdDate' => '2023-05-05T15:03:24',
      'lastModifiedDate' => '2023-05-05T15:03:24',
      'demographic' => nil,
      'contactInfo' => nil,
      'address' => nil,
    }
  end

  let!(:remote_credential) { create(:ac_hmis_warehouse_credential) }

  def stub_api(with_record: default_record)
    allow(job).to receive(:each_record_we_are_interested_in).and_yield(with_record)
  end

  def perform
    job.perform(actor_id: user.id)
  end

  it 'finds clients' do
    stub_api

    perform
    expect(job.clients).to eq([client])
  end

  it 'inserts a new MCI unique ID' do
    stub_api

    perform
    expect(HmisExternalApis::ExternalId.count).to eq(1)
    expect(client.external_ids.length).to eq(1)
    expect(client.external_ids.first.value).to eq('1000119810')
  end

  it 'updates an existing MCI unique ID' do
    stub_api
    perform

    default_record['mciUniqId'] = '999999'
    perform
    expect(HmisExternalApis::ExternalId.count).to eq(1)
    expect(client.external_ids.length).to eq(1)
    expect(client.external_ids.first.value).to eq('999999')
  end

  it 'triggers merge of duplicate mci unique IDs' do
    stub_api

    other_client = create(:hmis_hud_client, data_source: data_source)
    create(:mci_unique_id_external_id, value: '1000119810', remote_credential: remote_credential, source: other_client)

    allow(Hmis::MergeClientsJob).to receive(:perform_later).with(client_ids: [client.id, other_client.id].sort, actor_id: user.id)

    perform

    expect(job.merge_sets.length).to eq(1)
  end

  it 'triggers merge of duplicate mci unique IDs for source clients with the same destination id' do
    stub_api

    # Second Source Client that does not have an MCI Unique ID, but shares the same destination clients
    other_client = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
    other_client.warehouse_client_source.update(destination_id: client.warehouse_id)

    # confirm setup
    expect(client.destination_client.source_clients.size).to eq(2)
    expect(client.destination_client.source_clients.pluck(:id)).to contain_exactly(client.id, other_client.id)

    allow(Hmis::MergeClientsJob).to receive(:perform_later).with(client_ids: [client.id, other_client.id].sort, actor_id: user.id)

    perform

    expect(job.merge_sets.length).to eq(1)
  end
end
