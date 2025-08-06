###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_ce_processing_context'

RSpec.describe 'Concurrent CE Processing', type: :job do
  include ActiveJob::TestHelper
  include_context 'with ce processing setup'

  let!(:pool2) { create(:hmis_ce_match_candidate_pool) }
  let!(:opportunity2) { create(:hmis_ce_opportunity, candidate_pool: pool2) }

  before do
    Hmis::Ce::ChangeMarker.delete_all
  end

  describe 'end-to-end concurrent processing' do
    it 'processes all dirty records when both jobs run concurrently' do
      # Setup comprehensive dirty state
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: pool2, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: client2, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 0)

      # Run both jobs
      Hmis::Ce::ProcessPoolsJob.perform_now
      Hmis::Ce::ProcessClientsJob.perform_now

      # Verify all markers are processed
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool2).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3).processed_version).to eq(1)

      # Verify candidates were created by pool processing (both pools × 3 clients = 6)
      expect(Hmis::Ce::Match::Candidate.count).to eq(6)
    end

    it 'handles realistic processing cycle with arriving changes' do
      # Initial state: some pools and clients are dirty
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
      create(:hmis_ce_change_marker, trackable: client2, current_version: 2, processed_version: 1)

      # Step 1: ProcessPoolsJob runs (simulating longer interval)
      Hmis::Ce::ProcessPoolsJob.perform_now

      # Pool should be processed, candidates created
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)
      initial_candidate_count = Hmis::Ce::Match::Candidate.count
      expect(initial_candidate_count).to be > 0

      # Step 2: ProcessClientsJob runs (simulating shorter interval)
      Hmis::Ce::ProcessClientsJob.perform_now

      # Clients should be processed
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2).processed_version).to eq(2)

      # Step 3: New client changes arrive while system is running (simulate version bump)
      client3_marker = Hmis::Ce::ChangeMarker.find_by(trackable: client3)
      new_version = client3_marker.current_version + 1
      client3_marker.update!(current_version: new_version)

      # Step 4: ProcessClientsJob runs again
      Hmis::Ce::ProcessClientsJob.perform_now

      # New client should be processed (processed_version should catch up to current_version)
      client3_marker_after = Hmis::Ce::ChangeMarker.find_by(trackable: client3)
      expect(client3_marker_after.processed_version).to eq(new_version)

      # Verify system reaches consistent state
      expect(Hmis::Ce::ChangeMarker.dirty.count).to eq(0)
    end

    it 'handles coordinated reconciliation between jobs' do
      # Only track client1, leave others untracked
      create(:hmis_ce_change_marker, trackable: client1)

      # ProcessClientsJob should discover and track missing clients
      expect do
        Hmis::Ce::ProcessClientsJob.perform_now
      end.to change { Hmis::Ce::ChangeMarker.where(trackable_type: 'GrdaWarehouse::Hud::Client').count }.by(2)

      # ProcessPoolsJob should discover and track missing pools
      expect do
        Hmis::Ce::ProcessPoolsJob.perform_now
      end.to change { Hmis::Ce::ChangeMarker.where(trackable_type: 'Hmis::Ce::Match::CandidatePool').count }.by(2)

      # All records should now be tracked
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool2)).to be_present
    end
  end

  describe 'advisory lock coordination' do
    it 'ProcessClientsJob skips pools locked by ProcessPoolsJob' do
      create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
      # Prevent reconciliation from creating markers for client2 and client3
      create(:hmis_ce_change_marker, trackable: client2, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)

      # Mock pool2 to be locked (simulating ProcessPoolsJob is processing it)
      pool2_lock_name = "Hmis::Ce::PoolLock::#{pool2.id}"
      allow(::GrdaWarehouseBase).to receive(:with_advisory_lock).and_call_original
      allow(::GrdaWarehouseBase).to receive(:with_advisory_lock).with(
        pool2_lock_name,
        { timeout_seconds: 0 },
      ) do |_lock_name, _options|
        # Return false to indicate lock acquisition failed (pool is busy)
        false
      end

      # Should create candidate only for unlocked pool
      expect { Hmis::Ce::ProcessClientsJob.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(1)

      # Client should be marked as processed even though one pool was skipped
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)

      # Verify candidate was created only for the unlocked pool
      candidate_pools = Hmis::Ce::Match::Candidate.joins(:client_proxy).where('ce_client_proxies.client_id' => client1.id).pluck(:candidate_pool_id)
      expect(candidate_pools).to eq([pool.id]) # Only unlocked pool
    end
  end
end
