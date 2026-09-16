###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilderJob, type: :job do
  include ActiveJob::TestHelper

  let(:builder_class) { Hmis::Ce::Match::CandidatePoolBuilder }

  describe '#perform' do
    it 'forwards args to the builder within an open transaction, so the transaction-scoped lock stays held' do
      # lock_for_maintenance!'s transaction: true option only changes which pg lock function is used
      # (pg_try_advisory_xact_lock); it does not open a transaction itself. Without an explicit
      # transaction around it, the lock is released as soon as that single statement completes,
      # before the builder runs at all. Compare transaction depth (rather than transaction_open?,
      # which is always true here under RSpec's transactional test wrapping) to confirm the job opens
      # its own transaction, on top of the test's, around the real (unmocked) lock_for_maintenance!.
      base_depth = GrdaWarehouseBase.connection.open_transactions
      expect(builder_class).to receive(:call).with(force_reprocessing: true) do
        expect(GrdaWarehouseBase.connection.open_transactions).to be > base_depth
      end
      described_class.new.perform(force_reprocessing: true)
    end
  end

  describe 'concurrency' do
    it 'does not build pools and re-raises when the maintenance lock is already held' do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).
        and_raise(WithAdvisoryLock::FailedToAcquireLock.new('candidate-pool-maintenance'))

      expect(builder_class).not_to receive(:call)
      expect { described_class.new.perform }.to raise_error(WithAdvisoryLock::FailedToAcquireLock)
    end
  end

  describe 'enqueuing' do
    it 'runs on the long-running queue at maintenance priority' do
      described_class.perform_later
      enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(enqueued[:queue]).to eq(ENV.fetch('DJ_LONG_QUEUE_NAME', 'long_running').to_s)
      expect(enqueued[:priority]).to eq(BaseJob::MAINTENANCE_PRIORITY_15)
    end
  end
end
