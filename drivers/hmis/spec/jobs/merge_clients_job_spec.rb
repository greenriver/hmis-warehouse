###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  # Probably other specs aren't cleaning up:
  before(:all) { cleanup_test_environment }

  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_hud_user, data_source: data_source) }
  let(:client1) { create(:hmis_hud_client_complete, pronouns: nil, date_created: Time.now - 1.day, data_source: data_source) }

  let!(:client1_name) { create(:hmis_hud_custom_client_name, client: client1, first: client1.first_name, last: client1.last_name, middle: client1.middle_name, suffix: client1.name_suffix, data_source: data_source) }
  let!(:client1_contact_point) { create(:hmis_hud_custom_client_contact_point, client: client1, data_source: data_source) }
  let!(:client1_address) { create(:hmis_hud_custom_client_address, client: client1, data_source: data_source) }

  let(:client2) { create(:hmis_hud_client_complete, pronouns: 'she', data_source: data_source) }
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

  context 'main behaviors' do
    before(:each) { Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id) }

    it 'saves an audit trail' do
      expect(Hmis::ClientMergeAudit.count).to eq(1)
      audit = Hmis::ClientMergeAudit.first
      expect(audit.client_merge_histories.count).to eq(1)
      expect(Hmis::ClientMergeHistory.count).to eq(1)
      expect(Hmis::ClientMergeHistory.first).to have_attributes(
        retained_client_id: client1.id,
        deleted_client_id: client2.id,
        client_merge_audit_id: audit.id,
      )
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
      expected = [client1.full_name]

      result = client1.names.where(primary: true)

      expect(result.length).to eq(1)

      actual = result.map(&:full_name)

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
  end

  context 'when merged client has enrollment' do
    let!(:o1) { create :hmis_hud_organization, data_source: data_source, user: user }
    let!(:p1) { create(:hmis_hud_project, data_source: data_source, organization: o1) }
    let!(:e1) { create(:hmis_hud_wip_enrollment, client: client2, project: p1, data_source: data_source) }

    # This is a regression test for a bug where deleted rows in hmis_wips were still returned by project.enrollments_including_wip.
    # The bug was fixed by selecting only non-deleted rows in the hmis_client_projects view.
    it 'does not result in duplicate enrollment records' do
      e1.save_not_in_progress!
      expect(p1.enrollments_including_wip.count).to eq(1)
      Hmis::MergeClientsJob.perform_now(client_ids: [client1.id, client2.id], actor_id: actor.id)
      expect(p1.enrollments_including_wip.count).to eq(1), 'it hould not show dupes'
    end
  end

  context 'with duplicate mci_ids' do
    let(:mci_id_value) { 'test-123' }
    let!(:external_id_client_1) { create :mci_external_id, source: client1, remote_credential: mci_cred, value: mci_id_value }
    let!(:external_id_client_2) { create :mci_external_id, source: client2, remote_credential: mci_cred, value: mci_id_value }
    it 'merges and deduplicates external ids' do
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      expect(client1.ac_hmis_mci_ids.pluck(:value)).to contain_exactly(mci_id_value)
    end
  end

  context 'with unique mci_ids' do
    let!(:external_id_client_1) { create :mci_external_id, source: client1, remote_credential: mci_cred }
    let!(:external_id_client_2) { create :mci_external_id, source: client2, remote_credential: mci_cred }
    it 'merges external ids' do
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      expect(client1.ac_hmis_mci_ids.pluck(:value)).to contain_exactly(external_id_client_1.value, external_id_client_2.value)
    end
  end

  context 'with scan card codes' do
    let!(:code1) { create :hmis_scan_card_code, client: client1 }
    let!(:code2) { create :hmis_scan_card_code, client: client2 }
    let!(:code3) { create :hmis_scan_card_code, client: client2, deleted_at: Time.current }

    it 'moves all scan cards to retained client' do
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      expect(client1.scan_card_codes.with_deleted.pluck(:value)).to contain_exactly(code1.value, code2.value, code3.value)
    end
  end

  context 'with external referral records' do
    let!(:referral1) { create :hmis_external_api_ac_hmis_referral }
    let!(:referral1_hhm1) { create :hmis_external_api_ac_hmis_referral_household_member, client: client1, referral: referral1 }
    let!(:referral1_hhm2) { create :hmis_external_api_ac_hmis_referral_household_member, client: client2, referral: referral1 }
    let!(:referral2) { create :hmis_external_api_ac_hmis_referral }
    let!(:referral2_hhm2) { create :hmis_external_api_ac_hmis_referral_household_member, client: client2, referral: referral2 }

    it 'does not create duplicates when merging ReferralHouseholdMembers' do
      expect { Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id) }.
        to change(HmisExternalApis::AcHmis::ReferralHouseholdMember, :count).by(-1)

      expect(referral1_hhm1.reload.client_id).to eq(client1.id) # no change
      expect(HmisExternalApis::AcHmis::ReferralHouseholdMember.find_by(id: referral1_hhm2.id)).to be_nil # deleted
      expect(referral2_hhm2.reload.client_id).to eq(client1.id) # updated reference
    end
  end

  context 'client names' do
    let!(:c1_without_custom_name) { create(:hmis_hud_client_complete, date_created: Time.current - 3.days, data_source: data_source) }
    let!(:c2_without_custom_name) { create(:hmis_hud_client_complete, date_created: Time.current, data_source: data_source) }
    let!(:c3_with_custom_name) { create(:hmis_hud_client_complete, date_created: Time.current - 2.days, data_source: data_source, with_custom_client_name: true) }
    let!(:c4_with_custom_name) { create(:hmis_hud_client_complete, date_created: Time.current, data_source: data_source, with_custom_client_name: true) }
    let!(:c4_secondary_name) { create(:hmis_hud_custom_client_name, client: c4_with_custom_name, data_source: data_source) }

    it 'is set up correctly' do
      expect(c1_without_custom_name.names).to be_empty
      expect(c2_without_custom_name.names).to be_empty
      expect(c3_with_custom_name.names.size).to eq(1)
      expect(c3_with_custom_name.names.primary_names.size).to eq(1)
      expect(c4_with_custom_name.names.size).to eq(2)
      expect(c4_with_custom_name.names.primary_names.size).to eq(1)
    end

    it 'works when neither clients have a CustomClientName' do
      # Expected behavior: 2 CustomClientName records are created, one is primary, and its the one from the retained client
      c1 = c1_without_custom_name
      c2 = c2_without_custom_name
      original_name = c1.full_name

      client_ids = [c1.id, c2.id]
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

      c1.reload
      found_names = c1.names.map(&:full_name).sort
      expected_names = [c1, c2].map(&:full_name).sort
      expect(found_names).to eq(expected_names)
      expect(c1.names.primary_names.size).to eq(1)
      expect(c1.primary_name.full_name).to eq(original_name)
      expect(c1.full_name).to eq(original_name)
    end

    it 'works when both clients have CustomClientName(s)' do
      # Expected behavior: all CustomClientNames are retained, one is primary
      c1 = c3_with_custom_name
      c2 = c4_with_custom_name
      original_name = c1.full_name

      client_ids = [c1.id, c2.id]
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

      c1.reload
      found_names = c1.names.map(&:full_name).sort
      expected_names = [c1.names.map(&:full_name), c2.names.map(&:full_name)].flatten.uniq.sort
      expect(c1.names.size).to eq(3)
      expect(found_names).to eq(expected_names)
      expect(c1.names.primary_names.size).to eq(1)
      expect(c1.primary_name.full_name).to eq(original_name)
      expect(c1.full_name).to eq(original_name)
    end

    it 'works when 1 client has a CustomClientName and the other doesn\'t' do
      # Expected behavior: 1 CustomClientName is created, so there are 2 total, and 1 is primary
      c1 = c1_without_custom_name
      c2 = c3_with_custom_name
      original_name = c1.full_name

      client_ids = [c1.id, c2.id]
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

      c1.reload
      found_names = c1.names.map(&:full_name).sort
      expected_names = [c1, c2].map(&:full_name).sort
      expect(c1.names.size).to eq(2)
      expect(found_names).to eq(expected_names)
      expect(c1.names.primary_names.size).to eq(1)
      expect(c1.primary_name.full_name).to eq(original_name)
      expect(c1.full_name).to eq(original_name)
    end
  end

  context 'audit history' do
    let!(:c1) { create(:hmis_hud_client_complete, date_created: Time.current - 1.week, data_source: data_source) }
    let!(:c2) { create(:hmis_hud_client_complete, date_created: Time.current - 5.days, data_source: data_source) }
    let!(:c3) { create(:hmis_hud_client_complete, date_created: Time.current - 2.days, data_source: data_source) }
    let!(:c4) { create(:hmis_hud_client_complete, date_created: Time.current, data_source: data_source) }
    let!(:c5) { create(:hmis_hud_client_complete, date_created: Time.current, data_source: data_source) }

    it 'preserves audit history when client with merge history is merged' do
      expect(Hmis::ClientMergeAudit.count).to eq(0)

      # First merge: c4 and c5 into c3
      Hmis::MergeClientsJob.perform_now(client_ids: [c3.id, c4.id, c5.id], actor_id: actor.id)

      expect(Hmis::ClientMergeAudit.count).to eq(1)
      expect(Hmis::ClientMergeHistory.count).to eq(2)
      audit1 = Hmis::ClientMergeAudit.last
      expect(audit1.client_merge_histories.count).to eq(2)
      expect(audit1.client_merge_histories).to contain_exactly(
        have_attributes(retained_client_id: c3.id, deleted_client_id: c4.id),
        have_attributes(retained_client_id: c3.id, deleted_client_id: c5.id),
      )
      c3.reload
      expect(c3.merge_histories).to eq(audit1.client_merge_histories)
      expect(c3.merge_audits.map(&:id)).to contain_exactly(audit1.id)
      expect(c3.reverse_merge_histories).to be_empty

      c4.reload
      expect(c4.merge_histories).to be_empty
      expect(c4.reverse_merge_histories).to eq(audit1.client_merge_histories.where(deleted_client_id: c4.id))
      expect(c4.reverse_merge_audits.map(&:id)).to contain_exactly(audit1.id)

      # Second merge: c2 into c1
      Hmis::MergeClientsJob.perform_now(client_ids: [c2.id, c1.id], actor_id: actor.id)

      expect(Hmis::ClientMergeAudit.count).to eq(2)
      audit2 = Hmis::ClientMergeAudit.last
      expect(audit2.client_merge_histories.count).to eq(1)
      expect(audit2.client_merge_histories.first).to have_attributes(
        retained_client_id: c1.id,
        deleted_client_id: c2.id,
      )
      expect(Hmis::ClientMergeHistory.all).to contain_exactly(
        have_attributes(retained_client_id: c3.id, deleted_client_id: c4.id, client_merge_audit_id: audit1.id),
        have_attributes(retained_client_id: c3.id, deleted_client_id: c5.id, client_merge_audit_id: audit1.id),
        have_attributes(retained_client_id: c1.id, deleted_client_id: c2.id, client_merge_audit_id: audit2.id),
      )

      # Third merge: c3 into c1
      Hmis::MergeClientsJob.perform_now(client_ids: [c3.id, c1.id], actor_id: actor.id)

      expect(Hmis::ClientMergeAudit.count).to eq(3)
      audit3 = Hmis::ClientMergeAudit.last
      expect(audit3.client_merge_histories.count).to eq(1)
      expect(Hmis::ClientMergeHistory.all).to contain_exactly(
        # all updated to point to c1
        have_attributes(retained_client_id: c1.id, deleted_client_id: c4.id, client_merge_audit_id: audit1.id),
        have_attributes(retained_client_id: c1.id, deleted_client_id: c5.id, client_merge_audit_id: audit1.id),
        have_attributes(retained_client_id: c1.id, deleted_client_id: c2.id, client_merge_audit_id: audit2.id),
        have_attributes(retained_client_id: c1.id, deleted_client_id: c3.id, client_merge_audit_id: audit3.id),
      )
      expect(c1.reload.merge_histories).to eq(Hmis::ClientMergeHistory.all)
      expect(c1.merge_audits).to contain_exactly(audit1, audit2, audit3)
    end
  end

  context 'deduplication' do
    let!(:client2_name_dup) do
      d = client1_name.dup
      d.save!
      d
    end

    # Give client a different primary name
    let!(:client2_primary_name) do
      create(:hmis_hud_custom_client_name, client: client2, data_source: data_source)
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

    before { Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id) }

    it 'dedups non-primary names' do
      dup = [client1_name, client2_name_dup].max_by(&:id)
      expect(dup.reload).to be_deleted
      expect(client2_primary_name.reload).to be_present
    end

    it 'dedups addresses' do
      dup = [client1_address, client2_address_dup].max_by(&:id)
      expect(dup.reload).to be_deleted
    end

    it 'dedups contact points' do
      dup = [client1_contact_point, client2_contact_point_dup].max_by(&:id)
      expect(dup.reload).to be_deleted
    end

    it 'dedups custom data elements' do
      dup = [client1_custom_data_element, client2_data_element_dup].max_by(&:id)
      expect(dup.reload).to be_deleted
    end
  end
end
