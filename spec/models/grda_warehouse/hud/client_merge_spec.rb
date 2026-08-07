###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  let(:user) { create :user }
  let(:destination_ds) { create :destination_data_source }
  let(:source_ds) { create :source_data_source }

  describe 'when merging clients' do
    let(:sources) { create_list :hud_client, 2, data_source_id: source_ds.id }

    let(:prev_destination) { create :hud_client, data_source_id: destination_ds.id }
    let!(:prev_chronic_notes) do
      create_list :grda_warehouse_client_notes_chronic_justification, 3, client_id: prev_destination.id
    end
    let!(:prev_window_notes) do
      create_list :grda_warehouse_client_notes_window_note, 2, client_id: prev_destination.id
    end
    let!(:prev_hud_chronic) { create :hud_chronic, client_id: prev_destination.id, date: 1.months.ago }
    let!(:prev_chronic) { create :chronic, client_id: prev_destination.id, date: 1.months.ago }

    let(:new_destination) { create :hud_client, data_source_id: destination_ds.id }
    let!(:new_chronic_notes) do
      create_list :grda_warehouse_client_notes_chronic_justification, 3, client_id: new_destination.id
    end
    let!(:new_window_notes) do
      create_list :grda_warehouse_client_notes_window_note, 2, client_id: new_destination.id
    end
    let!(:new_hud_chronic) { create :hud_chronic, client_id: new_destination.id, date: 1.weeks.ago }
    let!(:new_chronic) { create :chronic, client_id: new_destination.id, date: 1.weeks.ago }

    describe 'prior to being merged' do
      before(:each) do
        GrdaWarehouse::WarehouseClient.create(
          destination_id: prev_destination.id,
          source_id: sources.first.id,
          id_in_source: 1,
        )

        GrdaWarehouse::WarehouseClient.create(
          destination_id: new_destination.id,
          source_id: sources.last.id,
          id_in_source: 1,
        )
      end
      after(:all) do
        # The enrollments and project sequences seem to drift.
        # This ensures we'll have one to test
        FactoryBot.reload
      end
      it 'previous client has 5 notes' do
        expect(prev_destination.notes.count).to eq 5
      end
      it 'previous client has 1 hud chronic' do
        expect(GrdaWarehouse::HudChronic.where(client_id: prev_destination.id).count).to eq 1
      end
      it 'previous client has 1 chronic' do
        expect(GrdaWarehouse::Chronic.where(client_id: prev_destination.id).count).to eq 1
      end
      it 'new destination has 5 notes' do
        expect(new_destination.notes.count).to eq 5
      end
      it 'new client has 1 hud chronic' do
        expect(GrdaWarehouse::HudChronic.where(client_id: new_destination.id).count).to eq 1
      end
      it 'new client has 1 chronic' do
        expect(GrdaWarehouse::Chronic.where(client_id: new_destination.id).count).to eq 1
      end
      describe 'after being merged' do
        before(:each) do
          new_destination.merge_from(prev_destination, reviewed_by: user, reviewed_at: Time.now)
        end
        describe 'any notes belonging to the previous client' do
          it 'should now belong to the new destination client' do
            expect(new_destination.notes.count).to eq 10
          end
          it 'should no longer be attached to the previous client' do
            expect(prev_destination.notes.count).to eq 0
          end
        end
        describe 'notes previously belonging to the new destination client' do
          it 'should still be attached to the new destination client' do
            expect(new_destination.notes.pluck(:id)).to include(*(new_chronic_notes.map(&:id) + new_window_notes.map(&:id)))
          end
        end

        it 'previous client has no hud chronic' do
          expect(GrdaWarehouse::HudChronic.where(client_id: prev_destination.id).count).to eq 0
        end
        it 'previous client has no chronic' do
          expect(GrdaWarehouse::Chronic.where(client_id: prev_destination.id).count).to eq 0
        end
        it 'new client has 2 hud chronic' do
          expect(GrdaWarehouse::HudChronic.where(client_id: new_destination.id).count).to eq 2
        end
        it 'new client has 2 chronic' do
          expect(GrdaWarehouse::Chronic.where(client_id: new_destination.id).count).to eq 2
        end
      end
    end
  end

  describe 'when splitting clients' do
    let!(:organization) { create(:hud_organization, data_source: source_ds) }
    let!(:project) { create(:hud_project, project_type: 13, organization: organization, data_source: source_ds) }
    let!(:source_clients) { create_list :hud_client, 3, data_source: source_ds, source_hash: 'test' }
    let!(:destination_client) { create :hud_client, data_source: destination_ds }
    let!(:warehouse_clients) do
      source_clients.each do |client|
        GrdaWarehouse::WarehouseClient.create!(
          id_in_source: client.PersonalID,
          source_id: client.id,
          destination_id: destination_client.id,
          data_source_id: client.data_source_id,
          source_hash: client.source_hash,
        )
      end
    end
    # Clients need enrollments or ClientCleanup will delete them
    let!(:enrollment) do
      two_years_ago = 2.years.ago
      source_clients.each do |client|
        # Ensure all enrollments fall outside of the normal cleanup window
        en = create(:hud_enrollment, client: client, project: project, data_source: source_ds, entry_date: two_years_ago.to_date)
        create(:hud_exit, enrollment_id: en.enrollment_id, personal_id: en.PersonalID, data_source: source_ds, exit_date: two_years_ago.to_date + 1.weeks)
      end
    end

    describe 'when splitting' do
      before do
        # Ensure all source clients have old modification dates
        # and that the destination client has the same modification date as the oldest source client (this is what we're testing)
        two_years_ago = 2.years.ago
        source_clients.each { |client| client.update(DateUpdated: two_years_ago, Asian: 0, race_none: 8) }
        update_date = two_years_ago - 1.weeks
        # Make the last source client have an older modification date and a race that doesn't match the other source clients
        # Ensure the destination client has the same modification date and race
        # This models a situation we have seen before, but should now be fixed
        source_clients.last.update(DateUpdated: update_date, Asian: 1, race_none: nil)
        destination_client.update(DateUpdated: update_date, Asian: 1, race_none: nil)
        GrdaWarehouse::Tasks::ClientCleanup.new.run!
      end
      describe 'prior to being split' do
        it 'all source clients are joined to the destination client and the destination client has the same modification date as the oldest source client' do
          aggregate_failures do
            expect(destination_client.source_clients).to contain_exactly(*source_clients)
            expect(destination_client.asian).to eq(source_clients.last.asian)
          end
        end
      end
      describe 'after splitting off a later-edited client' do
        include ActiveJob::TestHelper
        before do
          perform_enqueued_jobs do
            destination_client.split([source_clients.first.id], nil, [], user)
          end
        end
        it 'there are two destination clients and one contains only the first source client' do
          expect(destination_client.source_clients).to contain_exactly(*(source_clients - [source_clients.first]))
          expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
          new_destination = source_clients.first.destination_client
          expect(new_destination).to be_present
          expect(new_destination).to_not eq(destination_client)
          # new destination client asian should be the same as the source client's asian value
          expect(new_destination.asian).to eq(source_clients.first.asian)
          # destination client asian value should have been updated to match the second source client's asian value
          # since the second client has a more recent modification date
          expect(destination_client.reload.asian).to eq(source_clients.second.asian)
        end
      end
    end
  end

  describe '#move_dependent_hmis_items' do
    let(:previous) { create(:hud_client, data_source_id: destination_ds.id) }
    let(:new_client) { create(:hud_client, data_source_id: destination_ds.id) }

    it 'moves only the requested categories, leaving unrequested categories behind' do
      note = create(:grda_warehouse_client_notes_window_note, client_id: previous.id)
      file = create(:client_file, client: previous)

      new_client.move_dependent_hmis_items(previous.id, new_client.id, categories: [:notes])

      expect(note.reload.client_id).to eq(new_client.id)
      expect(file.reload.client_id).to eq(previous.id)
    end

    it 'moves CE Assessments and client-owned Custom Data Elements, which were previously never wired into the move logic' do
      ce_assessment = GrdaWarehouse::CoordinatedEntryAssessment::Individual.create!(
        client: previous,
        user: user,
        assessor: user,
      )
      cded = create(:hmis_custom_data_element_definition_for_color)
      custom_data_element = create(
        :hmis_custom_data_element,
        owner: Hmis::Hud::Client.find(previous.id),
        data_element_definition: cded,
        value_string: 'Blue',
      )

      new_client.move_dependent_hmis_items(previous.id, new_client.id, categories: [:ce_assessments, :custom_data_elements])

      expect(ce_assessment.reload.client_id).to eq(new_client.id)
      expect(custom_data_element.reload.owner_id).to eq(new_client.id)
    end

    it 'moves everything when no categories are specified, preserving merge_from behavior' do
      note = create(:grda_warehouse_client_notes_window_note, client_id: previous.id)
      chronic = create(:chronic, client_id: previous.id, date: 1.month.ago)

      new_client.move_dependent_hmis_items(previous.id, new_client.id)

      expect(note.reload.client_id).to eq(new_client.id)
      expect(chronic.reload.client_id).to eq(new_client.id)
    end
  end

  describe '#dependent_item_counts' do
    let(:client) { create(:hud_client, data_source_id: destination_ds.id) }

    it 'counts each category independently, including the newly-wired CE Assessments/Custom Data Elements and the aggregated Other bucket' do
      create_list(:grda_warehouse_client_notes_window_note, 2, client_id: client.id)
      create(:client_file, client: client)
      GrdaWarehouse::CoordinatedEntryAssessment::Individual.create!(client: client, user: user, assessor: user)
      cded = create(:hmis_custom_data_element_definition_for_color)
      create(:hmis_custom_data_element, owner: Hmis::Hud::Client.find(client.id), data_element_definition: cded, value_string: 'Green')
      create(:hud_chronic, client_id: client.id, date: 1.month.ago)
      create(:chronic, client_id: client.id, date: 1.month.ago)

      expect(client.dependent_item_counts).to eq(
        notes: 2,
        files: 1,
        vispdats: 0,
        cohort_assignments: 0,
        ce_assessments: 1,
        custom_data_elements: 1,
        other: 2,
      )
    end
  end

  describe '#split with per-category item movement' do
    let!(:organization) { create(:hud_organization, data_source: source_ds) }
    let!(:project) { create(:hud_project, project_type: 1, organization: organization, data_source: source_ds) }
    let!(:source_a) { create(:hud_client, data_source_id: source_ds.id) }
    let!(:source_b) { create(:hud_client, data_source_id: source_ds.id) }
    let!(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
    let!(:note) { create(:grda_warehouse_client_notes_window_note, client_id: destination_client.id) }
    let!(:client_file) { create(:client_file, client: destination_client) }

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_a.id, id_in_source: source_a.PersonalID)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_b.id, id_in_source: source_b.PersonalID)
      [source_a, source_b].each { |c| create(:hud_enrollment, client: c, project: project, data_source: source_ds, entry_date: 2.years.ago.to_date) }
    end

    it 'moves only the chosen categories to the chosen receiver' do
      destination_client.split([source_a.id], source_a.id, [:notes], user)

      new_destination = source_a.reload.destination_client
      expect(note.reload.client_id).to eq(new_destination.id)
      expect(client_file.reload.client_id).to eq(destination_client.id)
    end

    it 'moves nothing when no receiver is chosen, even if categories are checked' do
      destination_client.split([source_a.id], nil, [:notes, :files], user)

      expect(note.reload.client_id).to eq(destination_client.id)
      expect(client_file.reload.client_id).to eq(destination_client.id)
    end
  end

  describe '#data_source_deleted?' do
    it 'is true only once the data source has been soft-deleted' do
      active_ds = create(:source_data_source)
      deleted_ds = create(:source_data_source)
      active_client = create(:hud_client, data_source_id: active_ds.id)
      deleted_client = create(:hud_client, data_source_id: deleted_ds.id)

      deleted_ds.destroy

      expect(active_client.reload.data_source_deleted?).to be(false)
      expect(deleted_client.reload.data_source_deleted?).to be(true)
    end
  end

  describe '#active_source_clients' do
    let(:destination_client) { create(:hud_client, data_source_id: destination_ds.id) }
    let(:active_ds) { create(:source_data_source) }
    let(:deleted_ds) { create(:source_data_source) }
    let(:active_source) { create(:hud_client, data_source_id: active_ds.id) }
    let(:deleted_source) { create(:hud_client, data_source_id: deleted_ds.id) }

    before do
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: active_source.id, id_in_source: active_source.PersonalID)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: deleted_source.id, id_in_source: deleted_source.PersonalID)
      deleted_ds.destroy
    end

    it 'excludes source clients whose data source has been soft-deleted, even though both are joined' do
      expect(destination_client.active_source_clients).to contain_exactly(active_source)
    end

    it 'includes a second source client once its data source is confirmed non-deleted' do
      second_active_source = create(:hud_client, data_source_id: active_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: second_active_source.id, id_in_source: second_active_source.PersonalID)

      expect(destination_client.active_source_clients).to contain_exactly(active_source, second_active_source)
    end
  end

  describe '#potential_matches' do
    let(:client) { create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id) }

    it 'delegates to the shared client text search on this client\'s own name, excluding itself' do
      matching_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
      matching_destination = create(:hud_client, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: matching_destination.id, source_id: matching_source.id, id_in_source: matching_source.PersonalID)

      unrelated_source = create(:hud_client, FirstName: 'Zachary', LastName: 'Quinnson', data_source_id: source_ds.id)
      unrelated_destination = create(:hud_client, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: unrelated_destination.id, source_id: unrelated_source.id, id_in_source: unrelated_source.PersonalID)

      matches = client.potential_matches[:by_name]

      expect(matches).to include(matching_destination)
      expect(matches).not_to include(unrelated_destination)
    end

    it 'returns no matches when the client has a blank name' do
      blank_named_client = create(:hud_client, FirstName: '', LastName: '', data_source_id: source_ds.id)

      expect(blank_named_client.potential_matches).to eq({})
    end

    it "only includes candidates whose age matches at least one active source client's age" do
      client_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', DOB: 30.years.ago.to_date, data_source_id: source_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: client.id, source_id: client_source.id, id_in_source: client_source.PersonalID)

      age_match_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
      age_match_destination = create(:hud_client, DOB: 30.years.ago.to_date, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: age_match_destination.id, source_id: age_match_source.id, id_in_source: age_match_source.PersonalID)

      age_mismatch_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
      age_mismatch_destination = create(:hud_client, DOB: 5.years.ago.to_date, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: age_mismatch_destination.id, source_id: age_mismatch_source.id, id_in_source: age_mismatch_source.PersonalID)

      matches = client.potential_matches[:by_name]

      expect(matches).to include(age_match_destination)
      expect(matches).not_to include(age_mismatch_destination)
    end

    it "searches by each active source client's name, not just the destination's own name" do
      distinct_name_source = create(:hud_client, FirstName: 'Zachary', LastName: 'Quinnson', data_source_id: source_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: client.id, source_id: distinct_name_source.id, id_in_source: distinct_name_source.PersonalID)

      match_source = create(:hud_client, FirstName: 'Zachary', LastName: 'Quinnson', data_source_id: source_ds.id)
      match_destination = create(:hud_client, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: match_destination.id, source_id: match_source.id, id_in_source: match_source.PersonalID)

      matches = client.potential_matches[:by_name]

      expect(matches).to include(match_destination)
    end

    it 'does not filter by age when none of the active source clients have a DOB' do
      client_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', DOB: nil, data_source_id: source_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: client.id, source_id: client_source.id, id_in_source: client_source.PersonalID)

      candidate_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
      candidate_destination = create(:hud_client, DOB: 40.years.ago.to_date, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: candidate_destination.id, source_id: candidate_source.id, id_in_source: candidate_source.PersonalID)

      matches = client.potential_matches[:by_name]

      expect(matches).to include(candidate_destination)
    end

    it 'orders results by relevance, best match first' do
      exact_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
      exact_destination = create(:hud_client, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: exact_destination.id, source_id: exact_source.id, id_in_source: exact_source.PersonalID)

      fuzzy_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smither', data_source_id: source_ds.id)
      fuzzy_destination = create(:hud_client, data_source_id: destination_ds.id)
      GrdaWarehouse::WarehouseClient.create!(destination_id: fuzzy_destination.id, source_id: fuzzy_source.id, id_in_source: fuzzy_source.PersonalID)

      matches = client.potential_matches[:by_name].to_a

      expect(matches.index(exact_destination)).to be < matches.index(fuzzy_destination)
    end

    it "caps results at #{GrdaWarehouse::Hud::Client::POTENTIAL_MATCHES_LIMIT}" do
      (GrdaWarehouse::Hud::Client::POTENTIAL_MATCHES_LIMIT + 1).times do
        exact_source = create(:hud_client, FirstName: 'Roberta', LastName: 'Smithers', data_source_id: source_ds.id)
        exact_destination = create(:hud_client, data_source_id: destination_ds.id)
        GrdaWarehouse::WarehouseClient.create!(destination_id: exact_destination.id, source_id: exact_source.id, id_in_source: exact_source.PersonalID)
      end

      matches = client.potential_matches[:by_name]

      expect(matches.count).to eq(GrdaWarehouse::Hud::Client::POTENTIAL_MATCHES_LIMIT)
    end
  end
end
