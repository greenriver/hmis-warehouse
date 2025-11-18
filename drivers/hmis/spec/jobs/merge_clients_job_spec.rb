###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::MergeClientsJob, type: :model do
  let(:data_source) { create(:hmis_data_source) }

  let!(:client1) { create(:hmis_hud_client_complete, pronouns: nil, date_created: Date.current - 1.week, id: 2, data_source: data_source) }
  let!(:client2) { create(:hmis_hud_client_complete, pronouns: 'she', date_created: Date.current - 1.day, id: 1, data_source: data_source) }
  let(:clients) { [client1, client2] }
  let(:client_ids) { clients.map(&:id) }
  let(:actor) { create(:user) }

  describe 'basic merge behavior' do
    it 'minimal behavior: retains one client, soft-deletes the other, and updates attributes' do
      expect do
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      end.to change(Hmis::Hud::Client, :count).by(-1).
        and not_change(Hmis::Hud::Client.with_deleted, :count).
        and not_change(client1.reload, :date_deleted).from(nil)

      expect(client1.reload.pronouns).to eq('she')
      expect(client2.reload.deleted?).to be_truthy
    end

    it 'saves an audit trail' do
      expect do
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      end.to change(Hmis::ClientMergeAudit, :count).from(0).to(1).
        and change(Hmis::ClientMergeHistory, :count).from(0).to(1)

      audit = Hmis::ClientMergeAudit.first
      expect(audit.client_merge_histories.count).to eq(1)
      # Stores pre-merge mappings
      expect(audit.pre_merge_mappings).to be_present
      expect(audit.pre_merge_mappings).to be_a(Hash)

      merge_history = audit.client_merge_histories.first
      expect(merge_history).to have_attributes(
        retained_client_id: client1.id,
        deleted_client_id: client2.id,
        client_merge_audit_id: audit.id,
      )
    end

    context 'with CE enabled' do
      let(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }
      let(:client2) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
      end

      it 'marks the merged clients as dirty' do
        expect(Hmis::Ce::ChangeMarker.dirty.count).to eq(0)

        expect do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
        end.to change { Hmis::Ce::ChangeMarker.dirty.count }.by(1)

        expect(Hmis::Ce::ChangeMarker.sole.trackable).to eq(client1.destination_client.as_warehouse)
      end
    end

    describe 'error conditions' do
      it 'raises an error with empty array' do
        expect do
          Hmis::MergeClientsJob.perform_now(client_ids: [], actor_id: actor.id)
        end.to raise_error('You cannot merge less than two clients')
      end

      it 'raises an error with single client' do
        expect do
          Hmis::MergeClientsJob.perform_now(client_ids: [client1.id], actor_id: actor.id)
        end.to raise_error('You cannot merge less than two clients')
      end

      context 'with clients from different data sources' do
        let(:data_source2) { create(:hmis_data_source) }
        let!(:client_from_other_data_source) { create(:hmis_hud_client_complete) }

        it 'raises an error' do
          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: [client1.id, client_from_other_data_source.id], actor_id: actor.id)
          end.to raise_error('We should only have one data source!')
        end
      end
    end
  end

  describe 'client selection' do
    # client1 has lower ID, but was created more recently
    let!(:client1) { create(:hmis_hud_client, date_created: Date.current - 1.day, data_source: data_source) }
    let!(:client2) { create(:hmis_hud_client, date_created: Date.current - 1.week, data_source: data_source) }

    it 'retains the client with earliest date created (despite ID ordering)' do
      Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
      expect(Hmis::Hud::Client.exists?(client2.id)).to be_truthy
      expect(Hmis::Hud::Client.exists?(client1.id)).to be_falsey
    end

    context 'with missing DateCreated' do
      let!(:client1) { create(:hmis_hud_client_complete, data_source: data_source) }
      let!(:client2) { create(:hmis_hud_client_complete, data_source: data_source) }

      before do
        # manually set to nil, since setting this attribute in the factory doesn't work
        clients.each { |client| client.update_column(:DateCreated, nil) }
      end

      it 'handles clients with nil DateCreated, selecting lower client' do
        expect(client1.id < client2.id).to be_truthy
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
        expect(Hmis::Hud::Client.exists?(client1.id)).to be_truthy
        expect(Hmis::Hud::Client.exists?(client2.id)).to be_falsey
      end
    end

    context 'when DateCreated values are equal' do
      let(:date) { Date.current - 5.days }
      let!(:client1) { create(:hmis_hud_client_complete, date_created: date, data_source: data_source) }
      let!(:client2) { create(:hmis_hud_client_complete, date_created: date, data_source: data_source) }

      it 'breaks ties by client ID' do
        expect(client1.id < client2.id).to be_truthy
        Hmis::MergeClientsJob.perform_now(client_ids: [client1.id, client2.id], actor_id: actor.id)
        expect(Hmis::Hud::Client.exists?(client1.id)).to be_truthy
        expect(Hmis::Hud::Client.exists?(client2.id)).to be_falsey
      end
    end
  end

  describe 'related record updates' do
    let!(:client1) { create(:hmis_hud_client_complete, pronouns: nil, date_created: Date.current - 1.week, id: 2, data_source: data_source) }
    let!(:client2) { create(:hmis_hud_client_complete, pronouns: 'she', date_created: Date.current - 1.day, id: 1, data_source: data_source) }

    shared_examples 'merge that saves mappings' do |key, mapping_field, client_field|
      it 'stores mappings' do
        Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
        audit = Hmis::ClientMergeAudit.first
        mappings = audit.mappings_for(key)
        expect(mappings[record2.id]).to eq({ mapping_field => client2.send(client_field || mapping_field) })
        # expect(mappings.keys).not_to include(record1.id) # todo @martha - commented out because of client name
      end
    end

    describe 'PersonalID relationships' do
      # Shared example that expects fixtures: record1 (associated with the retained client1), record2 (associated with the deleted client2)
      shared_examples 'merge of records related by PersonalID' do
        it 'updates both records to point to the PersonalID of the retained client' do
          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
            [record1, record2].each(&:reload)
          end.to change(record2, :PersonalID).from(client2.PersonalID).to(client1.PersonalID).
            and not_change(record1, :PersonalID).from(client1.PersonalID)
        end
      end

      context 'with enrollments' do
        context 'with one enrollment on each client' do
          let!(:record1) { create(:hmis_hud_enrollment, client: client1, data_source: data_source) }
          let!(:record2) { create(:hmis_hud_enrollment, client: client2, data_source: data_source) }

          it_behaves_like 'merge of records related by PersonalID'
          it_behaves_like 'merge that saves mappings', 'enrollments', 'PersonalID'
        end

        context 'when merged client has WIP enrollment' do
          let!(:o1) { create :hmis_hud_organization, data_source: data_source }
          let!(:p1) { create(:hmis_hud_project, data_source: data_source, organization: o1) }
          let!(:e1) { create(:hmis_hud_wip_enrollment, client: client2, project: p1, data_source: data_source) }

          # This is a regression test for a bug where deleted rows in hmis_wips were still returned by project.enrollments_including_wip.
          # The bug was fixed by selecting only non-deleted rows in the hmis_client_projects view.
          it 'does not result in duplicate enrollment records' do
            e1.save_not_in_progress!
            expect(p1.enrollments.count).to eq(1)
            Hmis::MergeClientsJob.perform_now(client_ids: [client1.id, client2.id], actor_id: actor.id)
            expect(p1.enrollments.count).to eq(1), 'it should not show dupes'
          end
        end
      end

      context 'with names' do
        let!(:record1) { create(:hmis_hud_custom_client_name, client: client1, first: client1.first_name, last: client1.last_name, middle: client1.middle_name, suffix: client1.name_suffix, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_custom_client_name, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
        it_behaves_like 'merge that saves mappings', 'names', 'PersonalID'

        it 'merges both names onto the retained client' do
          make_set = ->(list) do
            list.map do |n|
              [n.first, n.last].join(' ')
            end.to_set
          end

          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

          found_names = make_set.call(client1.reload.names)
          expected_names = make_set.call([record1, record2])
          expect(found_names).to eq(expected_names)
        end

        it 'has correct primary name' do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

          client1.reload
          expected = [client1.full_name]

          result = client1.names.where(primary: true)

          expect(result.length).to eq(1)

          actual = result.map(&:full_name)

          expect(expected).to eq(actual)
        end
      end

      context 'with addresses' do
        let!(:record1) { create(:hmis_hud_custom_client_address, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_custom_client_address, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
        it_behaves_like 'merge that saves mappings', 'addresses', 'PersonalID'

        it 'merges both addresses onto the retained client' do
          make_set = ->(list) do
            list.map do |n|
              [n.address_type, n.line1, n.line2, n.city, n.state, n.district, n.country, n.postal_code].join(' ')
            end.to_set
          end

          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

          found_addresses = make_set.call(client1.reload.addresses)
          expected_addresses = make_set.call([record1, record2])

          expect(found_addresses).to eq(expected_addresses)
        end
      end

      context 'with contact points' do
        let!(:record1) { create(:hmis_hud_custom_client_contact_point, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_custom_client_contact_point, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
        it_behaves_like 'merge that saves mappings', 'contact_points', 'PersonalID'

        it 'merges both contact points onto the retained client' do
          make_set = ->(list) do
            list.map do |n|
              [n.use, n.system, n.value].join(' ')
            end.to_set
          end

          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)

          found_contact_points = make_set.call(client1.reload.contact_points)
          expected_contact_points = make_set.call([record1, record2])

          expect(found_contact_points).to eq(expected_contact_points)
        end
      end

      context 'with disability records' do
        let!(:record1) { create(:hmis_disability, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_disability, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with employment education records' do
        let!(:record1) { create(:hmis_employment_education, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_employment_education, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with event records' do
        let!(:record1) { create(:hmis_hud_event, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_event, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with health and DV records' do
        let!(:record1) { create(:hmis_health_and_dv, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_health_and_dv, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with income benefit records' do
        let!(:record1) { create(:hmis_income_benefit, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_income_benefit, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with service records' do
        let!(:record1) { create(:hmis_hud_service, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_service, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with current living situation records' do
        let!(:record1) { create(:hmis_current_living_situation, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_current_living_situation, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with youth education status records' do
        let!(:record1) { create(:hmis_youth_education_status, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_youth_education_status, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with exit records' do
        let!(:record1) { create(:hmis_hud_exit, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_exit, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with assessment records' do
        let!(:record1) { create(:hmis_hud_assessment, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_assessment, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with assessment question records' do
        let!(:record1) { create(:hmis_assessment_question, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_assessment_question, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with assessment result records' do
        let!(:record1) { create(:hmis_assessment_result, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_assessment_result, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with custom assessment records' do
        let!(:record1) { create(:hmis_custom_assessment, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_custom_assessment, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with custom case note records' do
        let!(:record1) { create(:hmis_hud_custom_case_note, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_hud_custom_case_note, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end

      context 'with custom service records' do
        let!(:record1) { create(:hmis_custom_service, client: client1, data_source: data_source) }
        let!(:record2) { create(:hmis_custom_service, client: client2, data_source: data_source) }

        it_behaves_like 'merge of records related by PersonalID'
      end
    end

    describe 'client_id relationships' do
      # Shared example that expects fixtures: record1 (associated with the retained client1), record2 (associated with the deleted client2)
      shared_examples 'merge of records related by client_id' do
        it 'updates both records to point to the client_id of the retained client' do
          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
            [record1, record2].each(&:reload)
          end.to change(record2, :client_id).from(client2.id).to(client1.id).
            and not_change(record1, :client_id).from(client1.id)
        end
      end

      context 'with client files' do
        let!(:record1) { create(:file, :without_validations, client_id: client1.id) }
        let!(:record2) { create(:file, :without_validations, client_id: client2.id) }

        it_behaves_like 'merge of records related by client_id'
        it_behaves_like 'merge that saves mappings', 'files', 'client_id', 'id'
      end

      context 'with ScanCardCode records' do
        let!(:record1) { create(:hmis_scan_card_code, client: client1) }
        let!(:record2) { create(:hmis_scan_card_code, client: client2) }
        let!(:deleted_scan_card_record) { create(:hmis_scan_card_code, client: client2, deleted_at: Time.current) }

        it 'moves all scan cards to retained client' do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          expect(client1.scan_card_codes.with_deleted.pluck(:value)).to contain_exactly(record1.value, record2.value, deleted_scan_card_record.value)
        end

        it_behaves_like 'merge of records related by client_id'
        it_behaves_like 'merge that saves mappings', 'scan_cards', 'client_id', 'id'
      end

      context 'with ClientLocationHistory::Location records' do
        let!(:record1) { create(:clh_location, client_id: client1.id) }
        let!(:record2) { create(:clh_location, client_id: client2.id) }

        it_behaves_like 'merge of records related by client_id'
        it_behaves_like 'merge that saves mappings', 'client_locations', 'client_id', 'id'
      end

      context 'with external referral records (legacy)' do
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

        # does not save mappings because this is legacy functionality
      end
    end

    describe 'custom data elements (owner_id relationships)' do
      let(:repeatable_data_element_definition) { create(:hmis_custom_data_element_definition_for_primary_language) }
      let!(:client1_custom_data_element) { create(:hmis_custom_data_element, owner: client1, value_string: 'English', data_element_definition: repeatable_data_element_definition, data_source: data_source) }
      let!(:client2_custom_data_element) { create(:hmis_custom_data_element, owner: client2, value_string: 'Russian', data_element_definition: repeatable_data_element_definition, data_source: data_source) }

      let(:non_repeatable_data_element_definition) { create(:hmis_custom_data_element_definition_for_color) }
      let!(:client1_nr_custom_data_element) { create(:hmis_custom_data_element, owner: client1, value_string: 'Blue', data_element_definition: non_repeatable_data_element_definition, data_source: data_source) }
      let!(:client2_nr_custom_data_element) { create(:hmis_custom_data_element, owner: client2, value_string: 'Red', data_element_definition:  non_repeatable_data_element_definition, data_source: data_source) }

      before(:each) { Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id) }

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

      it 'stores custom data element mappings' do
        audit = Hmis::ClientMergeAudit.first
        cde_mappings = audit.mappings_for('custom_data_elements')
        expect(cde_mappings).to be_a(Hash)
        # todo @martha - same situation for custom data elements, where the mapping is stored even when not changed
        expect(cde_mappings[client2_custom_data_element.id]).to eq({ 'owner_id' => client2.id })
        expect(cde_mappings[client2_nr_custom_data_element.id]).to eq({ 'owner_id' => client2.id })
      end
    end

    describe 'external ids (source_id relationships)' do
      let(:mci_cred) { create(:ac_hmis_mci_credential) }
      let(:mci_unique_id_cred) { create(:ac_hmis_warehouse_credential) }

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
        let!(:record1) { create :mci_external_id, source: client1, remote_credential: mci_cred }
        let!(:record2) { create :mci_external_id, source: client2, remote_credential: mci_cred }

        it 'merges external ids' do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          expect(client1.ac_hmis_mci_ids.pluck(:value)).to contain_exactly(record1.value, record2.value)
        end

        it_behaves_like 'merge that saves mappings', 'mci_ids', 'source_id', 'id'
      end

      context 'where merged client has mci_unique_id' do
        let!(:external_id_client_2) { create :mci_unique_id_external_id, source: client2, remote_credential: mci_unique_id_cred }

        it 'retains mci_unique_id' do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          expect(client1.ac_hmis_mci_unique_id&.value).to eq(external_id_client_2.value)
        end
      end

      context 'where retained client has mci_unique_id' do
        let!(:record2) { create :mci_unique_id_external_id, source: client1, remote_credential: mci_unique_id_cred }

        it 'retains mci_unique_id' do
          Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          expect(client1.ac_hmis_mci_unique_id&.value).to eq(record2.value)
        end

        # todo @martha - this isn't the case, it doesn't match the shared example
        # it_behaves_like 'merge that saves mappings', 'mci_unique_ids', 'source_id', 'id'
      end

      context 'where clients have different mci_unique_ids' do
        let!(:record1) { create :mci_unique_id_external_id, source: client1, remote_credential: mci_unique_id_cred }
        let!(:record2) { create :mci_unique_id_external_id, source: client2, remote_credential: mci_unique_id_cred }

        it 'retains one mci_unique_id' do
          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          end.to change(HmisExternalApis::ExternalId.mci_unique_ids, :count).by(-1)
          expect(client1.ac_hmis_mci_unique_id&.value).to eq(record1.value)
        end

        # todo @martha - this isn't the case, it doesn't save the mapping due to implementation, needs update?
        # it_behaves_like 'merge that saves mappings', 'mci_unique_ids', 'source_id', 'id'
      end

      context 'where clients have the same mci_unique_id' do
        let!(:external_id_client_1) { create :mci_unique_id_external_id, source: client1, remote_credential: mci_unique_id_cred }
        let!(:external_id_client_2) { create :mci_unique_id_external_id, source: client2, value: external_id_client_1.value, remote_credential: mci_unique_id_cred }

        it 'retains one mci_unique_id' do
          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: client_ids, actor_id: actor.id)
          end.to change(HmisExternalApis::ExternalId.mci_unique_ids, :count).by(-1)
          expect(client1.ac_hmis_mci_unique_id&.value).to eq(external_id_client_1.value)
        end
      end

      context 'with warehouse client records' do
        let!(:c1) { create(:hmis_hud_client_with_warehouse_client, date_created: Time.current - 1.day, data_source: data_source) }
        let!(:c2) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }

        it 'deletes warehouse clients for merged clients' do
          warehouse_client_ids = [c1, c2].map(&:destination_client).compact.map(&:id)
          expect(warehouse_client_ids.length).to eq(2)

          expect do
            Hmis::MergeClientsJob.perform_now(client_ids: [c1.id, c2.id], actor_id: actor.id)
          end.to change { GrdaWarehouse::WarehouseClient.where(source_id: c2.id).count }.from(1).to(0)

          expect(GrdaWarehouse::WarehouseClient.where(source_id: c1.id).count).to eq(1)
        end
      end
    end
  end

  describe 'client name special cases' do
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

  describe 'audit history preservation through multiple merges' do
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

  describe 'deduplication' do
    let!(:client1_name) { create(:hmis_hud_custom_client_name, client: client1, first: client1.first_name, last: client1.last_name, middle: client1.middle_name, suffix: client1.name_suffix, data_source: data_source) }
    let!(:client1_contact_point) { create(:hmis_hud_custom_client_contact_point, client: client1, data_source: data_source) }
    let!(:client1_address) { create(:hmis_hud_custom_client_address, client: client1, data_source: data_source) }

    let!(:client2_name) { create(:hmis_hud_custom_client_name, client: client2, data_source: data_source) }
    let!(:client2_contact_point) { create(:hmis_hud_custom_client_contact_point, client: client2, data_source: data_source) }
    let!(:client2_address) { create(:hmis_hud_custom_client_address, client: client2, data_source: data_source) }

    let(:repeatable_data_element_definition) { create(:hmis_custom_data_element_definition_for_primary_language) }
    let!(:client1_custom_data_element) { create(:hmis_custom_data_element, owner: client1, value_string: 'English', data_element_definition: repeatable_data_element_definition, data_source: data_source) }
    let!(:client2_custom_data_element) { create(:hmis_custom_data_element, owner: client2, value_string: 'Russian', data_element_definition: repeatable_data_element_definition, data_source: data_source) }

    let!(:client2_name) { create(:hmis_hud_custom_client_name, client: client2, data_source: data_source) }
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

    context 'with whitespace differences' do
      let!(:c1) { create(:hmis_hud_client_complete, date_created: Time.current - 1.day, data_source: data_source) }
      let!(:c2) { create(:hmis_hud_client_complete, data_source: data_source) }
      let!(:name1) { create(:hmis_hud_custom_client_name, client: c1, first: 'John', last: 'Doe', data_source: data_source) }
      let!(:name2) { create(:hmis_hud_custom_client_name, client: c2, first: '  John  ', last: '  Doe  ', data_source: data_source) }

      it 'treats names with different whitespace as duplicates' do
        Hmis::MergeClientsJob.perform_now(client_ids: [c1.id, c2.id], actor_id: actor.id)

        c1.reload
        expect(c1.names.count).to eq(1)
      end
    end

    context 'with case differences' do
      let!(:c1) { create(:hmis_hud_client_complete, date_created: Time.current - 1.day, data_source: data_source) }
      let!(:c2) { create(:hmis_hud_client_complete, data_source: data_source) }
      let!(:cp1) { create(:hmis_hud_custom_client_contact_point, client: c1, value: 'test@example.com', data_source: data_source) }
      let!(:cp2) { create(:hmis_hud_custom_client_contact_point, client: c2, value: 'TEST@EXAMPLE.COM', system: cp1.system, data_source: data_source) }

      it 'treats contact points with different case as duplicates' do
        Hmis::MergeClientsJob.perform_now(client_ids: [c1.id, c2.id], actor_id: actor.id)

        c1.reload
        expect(c1.contact_points.count).to eq(1)
      end
    end
  end
end
