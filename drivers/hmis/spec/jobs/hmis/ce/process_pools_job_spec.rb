###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_ce_processing_context'

RSpec.describe Hmis::Ce::ProcessPoolsJob, type: :job do
  include ActiveJob::TestHelper
  include_context 'with ce processing setup'

  before do
    Hmis::Ce::ChangeMarker.delete_all
  end

  it 'processes dirty pools against all clients' do
    create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)

    # We expect the job to create candidates for all 3 clients
    expect { described_class.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(3)

    expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)

    # Verify that candidates were created for the correct clients
    client_ids = [client1.id, client2.id, client3.id]
    candidate_client_ids = Hmis::Ce::Match::Candidate.joins(:client_proxy).where(candidate_pool: pool).pluck('ce_client_proxies.client_id')
    expect(candidate_client_ids).to match_array(client_ids)
  end

  it 'processes multiple dirty pools' do
    pool2 = create(:hmis_ce_match_candidate_pool_active, data_source: ce_data_source)

    create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)
    create(:hmis_ce_change_marker, trackable: pool2, current_version: 1, processed_version: 0)

    # Should create candidates for both pools (3 clients each = 6 total)
    expect { described_class.perform_now }.to change(Hmis::Ce::Match::Candidate, :count).by(6)

    # Both pools should be marked as processed
    expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool).processed_version).to eq(1)
    expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool2).processed_version).to eq(1)
  end

  it 'handles missing pools gracefully' do
    pool_id = pool.id
    # Create marker first, then destroy the pool
    create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)

    # Remove unit group first to avoid deletion restriction
    unit_group.destroy!
    pool.destroy!

    # Should not raise an error and should clean up the marker
    expect { described_class.perform_now }.not_to raise_error
    expect(Hmis::Ce::ChangeMarker.find_by(trackable_id: pool_id, trackable_type: 'Hmis::Ce::Match::CandidatePool')).to be_nil
  end

  context 'when no dirty pools' do
    it 'does not call the match engine' do
      create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 1)

      expect(Hmis::Ce::Match::Engine).not_to receive(:call)
      described_class.perform_now
    end
  end

  context 'with untracked records' do
    it 'creates change markers for untracked pools' do
      # pool is untracked
      create(:hmis_ce_change_marker, trackable: client1)

      expect do
        described_class.perform_now
      end.to change(Hmis::Ce::ChangeMarker, :count).by(1) # pool only

      expect(Hmis::Ce::ChangeMarker.find_by(trackable: pool)).to be_present
    end
  end

  context 'self-scheduling behavior' do
    context 'when dirty pools remain after processing' do
      let(:batch_size) { 3 }

      before do
        # Create initial dirty pool
        create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)

        # Create exactly batch_size additional pools to exceed the batch limit
        # This ensures some pools remain dirty after the first batch
        batch_size.times do
          additional_pool = create(:hmis_ce_match_candidate_pool_active, data_source: ce_data_source)
          create(:hmis_ce_change_marker, trackable: additional_pool, current_version: 1, processed_version: 0)
        end

        # Clear jobs enqueued during setup
        clear_enqueued_jobs
      end

      it 'schedules next batch when wait_time is provided and dirty pools remain' do
        travel_to Time.current do
          described_class.perform_now(wait_time: 5.minutes, batch_size: batch_size)

          enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
          expect(enqueued_job).to be_present
          expect(enqueued_job[:at].to_i).to eq((Time.current + 5.minutes).to_i)
          expect(enqueued_job[:args].first['batch_size']).to eq(batch_size)
        end
      end

      it 'does not schedule next batch when wait_time is nil' do
        described_class.perform_now(wait_time: nil, batch_size: batch_size)

        enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
        expect(enqueued_job).to be_nil
      end
    end

    context 'when no dirty pools remain after processing' do
      let(:batch_size) { 5 }

      before do
        # Create fewer pools than batch size so all get processed in one batch
        create(:hmis_ce_change_marker, trackable: pool, current_version: 1, processed_version: 0)

        2.times do
          additional_pool = create(:hmis_ce_match_candidate_pool_active, data_source: ce_data_source)
          create(:hmis_ce_change_marker, trackable: additional_pool, current_version: 1, processed_version: 0)
        end

        # Clear jobs enqueued during setup
        clear_enqueued_jobs
      end

      it 'does not schedule next batch even when wait_time is provided' do
        travel_to Time.current do
          described_class.perform_now(wait_time: 5.minutes, batch_size: batch_size)

          enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
          expect(enqueued_job).to be_nil
        end
      end
    end
  end

  it_behaves_like 'a job that can be enqueued if not already running', wait_time: 5.minutes

  describe 'queue configuration' do
    it 'runs on the long_running queue' do
      expect(described_class.queue_name).to eq(ENV.fetch('DJ_LONG_QUEUE_NAME', 'long_running'))
    end
  end
end
