###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_hud_user, data_source: data_source) }
  let(:client1) { create(:hmis_hud_client, pronouns: nil, date_created: Time.now - 1.day, data_source: data_source) }

  let!(:client1_name) { create(:hmis_hud_custom_client_name, client: client1, first: client1.first_name, last: client1.last_name, middle: client1.middle_name, suffix: client1.name_suffix, data_source: data_source) }
  let!(:client1_contact_point) { create(:hmis_hud_custom_client_contact_point, client: client1, data_source: data_source) }
  let!(:client1_address) { create(:hmis_hud_custom_client_address, client: client1, data_source: data_source) }

  let(:client2) { create(:hmis_hud_client, pronouns: 'she', data_source: data_source) }
  let!(:client2_name) { create(:hmis_hud_custom_client_name, client: client2, data_source: data_source) }
  let!(:client2_contact_point) { create(:hmis_hud_custom_client_contact_point, client: client2, data_source: data_source) }
  let!(:client2_address) { create(:hmis_hud_custom_client_address, client: client2, data_source: data_source) }

  let!(:client2_related_by_personal_id) { create(:hmis_hud_enrollment, client: client2, data_source: data_source) }
  let!(:client2_related_by_client_id) { create(:client_file, client_id: client2.id) }

  let(:clients) { [client1, client2] }
  let(:client_ids) { clients.map(&:id) }
  let(:actor) { create(:user) }

  # Probably other specs aren't cleaning up:
  before(:all) { Hmis::Hud::Client.destroy_all }
  before(:all) { GrdaWarehouse::DataSource.destroy_all }

  before { Hmis::MergeClientsJob.new.perform(client_ids: client_ids, actor_id: actor.id) }

  it 'saves an audit trail' do
    expect(Hmis::ClientMergeAudit.count).to eq(1)
  end

  it 'minimally seems to merge correctly' do
    expect(client1.date_created).to be < client2.date_created
    expect(client1.reload.pronouns).to eq('she')
  end

  it 'updates references to the merged clients related by PersonalID' do
    expect(client2_related_by_personal_id.reload.client).to eq(client1)
  end

  it 'updates references to the merged clients related by client_id' do
    expect(client2_related_by_client_id.reload.client.id).to eq(client1.id)
  end

  it 'includes custom attributes when updating references' do
    raise("I don't yet know what this means")
  end

  it 'merges names' do
    make_set = ->(list) do
      list.map do |n|
        [n.first, n.last].join(' ')
      end.to_set
    end

    found_names = make_set.call(client1.reload.names)
    expected_names = make_set.call([client1_name, client2_name])
    expect(found_names).to eq(expected_names)
  end

  it 'has correct primary name' do
    client1.reload
    expected = [client1.first_name, client1.middle_name, client1.last_name, client1.name_suffix].join(' ')

    result = client1.names.where(primary: true)

    expect(result.length).to eq(1)

    actual = [result.first.first, result.first.middle, result.first.last, result.first.suffix].join(' ')

    expect(expected).to eq(actual)
  end

  it 'merges addresses' do
    make_set = ->(list) do
      list.map do |n|
        [n.address_type, n.line1, n.line2, n.city, n.state, n.district, n.country, n.postal_code].join(' ')
      end.to_set
    end

    found_addresses = make_set.call(client1.reload.addresses)
    expected_addresses = make_set.call([client1_address, client2_address])

    expect(found_addresses).to eq(expected_addresses)
  end

  it 'merges contact points' do
    make_set = ->(list) do
      list.map do |n|
        [n.use, n.system, n.value].join(' ')
      end.to_set
    end

    found_contact_points = make_set.call(client1.reload.contact_points)
    expected_contact_points = make_set.call([client1_contact_point, client2_contact_point])

    expect(found_contact_points).to eq(expected_contact_points)
  end

  it 'soft-deletes the merged clients' do
    expect(Hmis::Hud::Client.count).to eq(1)
    expect(Hmis::Hud::Client.with_deleted.count).to eq(2)
    expect(client2.reload.deleted?).to be_truthy
  end

  context 'deduplication' do
    # let!(:client2_name_dup) do
    #   d = client1_name.dup
    #   d.save!
    #   d
    # end

    # let!(:client2_contact_point_dup) do
    #   d = client1_contact_point.dup
    #   d.save!
    #   d
    # end

    # let!(:client2_address_dup) do
    #   d = client1_address.dup
    #   d.save!
    #   d
    # end
    # it 'dedups names' do
    #   expect(client2_name_dup.reload).to be_deleted
    # end

    # it 'dedups addresses' do
    #   expect(client2_address_dup.reload).to be_deleted
    # end

    # it 'dedups contact points' do
    #   expect(client2_contact_point_dup.reload).to be_deleted
    # end
  end
end
