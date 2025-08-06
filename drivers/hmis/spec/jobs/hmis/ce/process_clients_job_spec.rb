###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_ce_processing_context'

RSpec.describe Hmis::Ce::ProcessClientsJob, type: :job do
  include ActiveJob::TestHelper
  include_context 'with ce processing setup'

  before do
    Hmis::Ce::ChangeMarker.delete_all
  end

  it 'processes dirty clients against active pools' do
    create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
    create(:hmis_ce_change_marker, trackable: client2, current_version: 2, processed_version: 1)
    create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)

    # We expect the job to create candidates for dirty clients (client1 and client2)
    expect { described_class.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(2)

    # Check markers are processed
    expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)
    expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2).processed_version).to eq(2)
    expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3).processed_version).to eq(1) # unchanged

    # Verify candidates were created for the correct clients
    candidate_client_ids = Hmis::Ce::Match::Candidate.joins(:client_proxy).where(candidate_pool: pool).pluck('ce_client_proxies.client_id')
    expect(candidate_client_ids).to match_array([client1.id, client2.id])
  end

  it 'processes clients against multiple active pools' do
    pool2 = create(:hmis_ce_match_candidate_pool)
    create(:hmis_ce_opportunity, candidate_pool: pool2)

    # Explicitly create markers for all clients to make test deterministic
    create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 0)
    create(:hmis_ce_change_marker, trackable: client2, current_version: 1, processed_version: 1)
    create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)

    # Should create candidates for dirty client (client1) against both pools = 2 candidates
    expect { described_class.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(2)

    expect(Hmis::Ce::ChangeMarker.find_by(trackable: client1).processed_version).to eq(1)

    # Verify candidates were created in both pools for client1 only
    pool_candidate_counts = [pool.id, pool2.id].map do |pool_id|
      Hmis::Ce::Match::Candidate.where(candidate_pool_id: pool_id).count
    end
    expect(pool_candidate_counts).to eq([1, 1]) # 1 dirty client in each pool
  end

  context 'when no dirty clients' do
    it 'does not call the match engine' do
      create(:hmis_ce_change_marker, trackable: client1, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: client2, current_version: 1, processed_version: 1)
      create(:hmis_ce_change_marker, trackable: client3, current_version: 1, processed_version: 1)

      expect(Hmis::Ce::Match::Engine).not_to receive(:call)
      described_class.perform_now
    end
  end

  context 'with untracked records' do
    it 'creates change markers for untracked clients' do
      # client2, client3 are untracked
      create(:hmis_ce_change_marker, trackable: client1)

      expect do
        described_class.perform_now
      end.to change(Hmis::Ce::ChangeMarker, :count).by(2) # client2, client3 only (ProcessClientsJob doesn't reconcile pools)

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client2)).to be_present
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: client3)).to be_present
      # Pool reconciliation is handled by ProcessPoolsJob, not ProcessClientsJob
      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool)).to be_nil
    end
  end

  context 'with self-scheduling' do
    it 'schedules next batch when wait_time is provided' do
      travel_to now do
        described_class.perform_now(wait_time: 1.minute)

        enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
        expect(enqueued_job).to be_present
        expect(enqueued_job[:at].to_i).to eq((now + 1.minute).to_i)
      end
    end

    it 'does not schedule next batch when wait_time is nil' do
      described_class.perform_now(wait_time: nil)

      enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
      expect(enqueued_job).to be_nil
    end
  end

  describe '.enqueue_if_not_already_running' do
    it 'enqueues job when none are running' do
      expect { described_class.enqueue_if_not_already_running(wait_time: 1.minute) }.
        to have_enqueued_job(described_class)
    end

    it 'does not enqueue job when one is already queued' do
      # First job
      described_class.perform_later(wait_time: 1.minute)
      # Clear the jobs queue to simulate the check
      clear_enqueued_jobs

      # Mock the jobs_for_class to return a job (simulating one already queued)
      allow(Delayed::Job).to receive(:jobs_for_class).with(described_class.name).and_return([double('job')])

      expect { described_class.enqueue_if_not_already_running(wait_time: 1.minute) }.
        not_to have_enqueued_job(described_class)
    end
  end

  describe 'queue configuration' do
    it 'runs on the default queue' do
      expect(described_class.queue_name).to eq('default')
    end
  end
end
