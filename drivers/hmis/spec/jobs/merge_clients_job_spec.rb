###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  # Probably other specs aren't cleaning up:
  before(:all) { cleanup_test_environment }

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

  let(:repeatable_data_element_definition) { create(:hmis_custom_data_element_definition_for_primary_language) }
  let!(:client1_custom_data_element) { create(:hmis_custom_data_element, owner: client1, value_string: 'English', data_element_definition: repeatable_data_element_definition, data_source: data_source) }
  let!(:client2_custom_data_element) { create(:hmis_custom_data_element, owner: client2, value_string: 'Russian', data_element_definition: repeatable_data_element_definition, data_source: data_source) }

  let(:non_repeatable_data_element_definition) { create(:hmis_custom_data_element_definition_for_color) }
  let!(:client1_nr_custom_data_element) { create(:hmis_custom_data_element, owner: client1, value_string: 'Blue', data_element_definition: non_repeatable_data_element_definition, data_source: data_source) }
  let!(:client2_nr_custom_data_element) { create(:hmis_custom_data_element, owner: client2, value_string: 'Red', data_element_definition:  non_repeatable_data_element_definition, data_source: data_source) }

  let(:clients) { [client1, client2] }
  let(:client_ids) { clients.map(&:id) }
  let(:actor) { create(:user) }

  let(:mci_cred) { create(:ac_hmis_mci_credential) }
  let!(:external_id_client_1) { create :mci_external_id, source: client1, remote_credential: mci_cred }
  let!(:external_id_client_2) { create :mci_external_id, source: client2, remote_credential: mci_cred }

  context 'main behaviors' do
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

    it 'merges repeating custom data elements' do
      client1.reload
      scope = client1.custom_data_elements.where(value_string: ['English', 'Russian'])

      expect(scope.map(&:value_string).to_set.length).to eq(2)
      expect(scope.all?(&:valid?)).to be_truthy
    end

    it 'merges non-repeating custom data elements, choosing newest' do
      client1.reload

      scope = client1.custom_data_elements.where(value_string: ['Red', 'Blue'])

      expect(scope.map(&:value_string).to_set.length).to eq(1)
      expect(scope.first.value_string).to eq('Red') # Created later than Blue
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
      Hmis::Hud::Client.with_deleted.reload
      puts "SEARCHFORME: #{ap Hmis::Hud::Client.with_deleted}" if Hmis::Hud::Client.with_deleted.count != 2
      expect(Hmis::Hud::Client.with_deleted.count).to eq(2)
      expect(client2.reload.deleted?).to be_truthy
    end

    it 'merges external ids' do
      byebug
      expect(client1.ac_hmis_mci_ids.pluck(:value).sort).to eq([external_id_client_1, external_id_client_2].map(&:value).sort)
    end

  end

  context 'deduplication' do
    let!(:client2_name_dup) do
      d = client1_name.dup
      d.save!
      d
    end

    let!(:client2_contact_point_dup) do
      d = client1_contact_point.dup
      d.save!
      d
    end

    let!(:client2_address_dup) do
      d = client1_address.dup
      d.save!
      d
    end

    let!(:client2_data_element_dup) do
      d = client1_custom_data_element.dup
      d.owner_id = client2.id
      d.save!
      d
    end

    before { Hmis::MergeClientsJob.new.perform(client_ids: client_ids, actor_id: actor.id) }

    it 'dedups names' do
      expect(client2_name_dup.reload).to be_deleted
    end

    it 'dedups addresses' do
      expect(client2_address_dup.reload).to be_deleted
    end

    it 'dedups contact points' do
      expect(client2_contact_point_dup.reload).to be_deleted
    end

    it 'dedups custom data elements' do
      expect(client2_data_element_dup.reload).to be_deleted
    end
  end
end
