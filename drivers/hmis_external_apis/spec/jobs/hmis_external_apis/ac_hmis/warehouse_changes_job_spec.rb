###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  it 'soft-merges duplicate MCI unique IDs' do
    stub_api

    destination_id = client.warehouse_id

    # Second source client with different destination client but same MCI unique ID
    other_client = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
    expect(other_client.warehouse_id).not_to eq(destination_id) # Confirm setup
    create(:mci_unique_id_external_id, value: '1000119810', remote_credential: remote_credential, source: other_client)

    # hard-merge job should NOT be called
    expect(Hmis::MergeClientsJob).not_to receive(:perform_later)

    # mock the ServiceHistory::Add task and assert it is called
    expect(GrdaWarehouse::Tasks::ServiceHistory::Add).
      to receive(:new).with(force_sequential_processing: true).
      and_return(instance_double(GrdaWarehouse::Tasks::ServiceHistory::Add, run!: true))

    expect do
      perform
      expect(job.merge_sets.length).to eq(1)

      client.reload
      other_client.reload
    end.to change(other_client, :warehouse_id).to(destination_id).
      and not_change(client, :warehouse_id)

    # Confirm soft merge: both source clients now point to the same destination
    expect(client.warehouse_id).to eq(other_client.warehouse_id)
  end

  it 'takes no merge action for duplicate MCI unique IDs when source clients already share same destination' do
    stub_api

    # Second source client sharing the same destination; no repointing needed
    other_client = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
    create(:mci_unique_id_external_id, value: '1000119810', remote_credential: remote_credential, source: other_client)
    other_client.warehouse_client_source.update(destination_id: client.warehouse_id)

    # confirm setup
    expect(client.destination_client.source_clients.size).to eq(2)
    expect(client.destination_client.source_clients.pluck(:id)).to contain_exactly(client.id, other_client.id)
    expect(Hmis::MergeClientsJob).not_to receive(:perform_later)

    # ServiceHistory::Add task should not be called, since no change is made
    expect(GrdaWarehouse::Tasks::ServiceHistory::Add).not_to receive(:new)

    expect do
      perform
      expect(job.merge_sets.length).to eq(1)

      client.reload
      other_client.reload
    end.to not_change(client, :warehouse_id).
      and not_change(other_client, :warehouse_id)

    # unchanged from before, no soft merge was needed
    expect(client.warehouse_id).to eq(other_client.warehouse_id)
  end

  it 'takes no merge action for duplicate MCI unique IDs when the source clients were previously split' do
    stub_api

    # Second source client with different destination client but same MCI unique ID
    other_client = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
    create(:mci_unique_id_external_id, value: '1000119810', remote_credential: remote_credential, source: other_client)

    # Perform the WarehouseChangesJob for the first time, which soft-merges the source clients, pointing them to the same destination
    perform
    expect(client.reload.warehouse_id).to eq(other_client.reload.warehouse_id)

    # Split the other_client out
    client.destination_client.as_warehouse.split([other_client.id], nil, nil, user)
    expect(other_client.reload.warehouse_id).not_to eq(client.reload.warehouse_id)
    expect(GrdaWarehouse::ClientSplitHistory.exists?(split_from: client.destination_client.id)).to be_truthy

    # Perform the WarehouseChangesJob again, which should take no action because the source clients were previously split
    perform
    expect(client.reload.warehouse_id).not_to eq(other_client.reload.warehouse_id)
  end

  context 'when there are multiple sets of multiple duplicate MCIs' do
    let!(:clients_by_mci) do
      # Create 3 sets of 3 clients each with different MCI unique IDs
      3.times.each_with_object({}) do |i, h|
        mci_uniq_id = "99999#{i}"
        h[mci_uniq_id] = []

        3.times do
          c = create(:hmis_hud_client_with_warehouse_client, data_source: data_source)
          create(:mci_unique_id_external_id, value: mci_uniq_id, remote_credential: remote_credential, source: c)
          h[mci_uniq_id] << c
        end
      end
    end

    it 'soft-merges all sets of duplicates' do
      stub_api

      expected_winner_destination_ids = clients_by_mci.transform_values do |clients|
        clients.map(&:warehouse_id).min
      end

      perform

      expect(job.merge_sets.length).to eq(3)

      # Assert soft-merge behavior: each MCI set converges on one "winner" destination ID
      clients_by_mci.each do |mci_uniq_id, clients|
        clients.each(&:reload)
        winner_destination_id = expected_winner_destination_ids.fetch(mci_uniq_id)
        expect(clients.map(&:warehouse_id).uniq).to eq([winner_destination_id])
      end
    end
  end
end
