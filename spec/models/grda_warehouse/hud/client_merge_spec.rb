###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
            destination_client.split([source_clients.first.id], nil, nil, user)
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
end
