###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalHandlerPlugin do
  let(:worker) { Delayed::Worker.new }
  let(:job) { Delayed::Job.new(id: 123) }
  let(:lifecycle) { Delayed::Lifecycle.new }

  before do
    # Clear thread-local storage before each test
    Thread.current[:delayed_job_worker] = nil
    # Apply the plugin callbacks to our test lifecycle
    SignalHandlerPlugin.callback_block.call(lifecycle)
  end

  after do
    # Clean up thread-local storage after each test to prevent leakage
    Thread.current[:delayed_job_worker] = nil
  end

  describe 'callbacks' do
    it 'registers the plugin' do
      expect(Delayed::Worker.plugins).to include(SignalHandlerPlugin)
    end

    it 'registers the worker in thread-local storage during performance' do
      lifecycle.run_callbacks(:perform, worker, job) do
        expect(Thread.current[:delayed_job_worker]).to eq(worker)
      end

      expect(Thread.current[:delayed_job_worker]).to be_nil
    end

    it 'unregisters the worker even if perform raises' do
      expect do
        lifecycle.run_callbacks(:perform, worker, job) { raise 'boom' }
      end.to raise_error('boom')

      expect(Thread.current[:delayed_job_worker]).to be_nil
    end
  end

  describe '.current_worker_stopping?' do
    it 'returns true if the registered worker is stopping' do
      lifecycle.run_callbacks(:perform, worker, job) do
        worker.stop
        expect(SignalHandlerPlugin.current_worker_stopping?).to be true
      end
    end

    it 'returns false if the registered worker is not stopping' do
      lifecycle.run_callbacks(:perform, worker, job) do
        expect(SignalHandlerPlugin.current_worker_stopping?).to be false
      end
    end

    it 'returns false if no worker is registered' do
      expect(SignalHandlerPlugin.current_worker_stopping?).to be false
    end
  end

  describe '.stop_current_worker!' do
    it 'stops the worker bound to the current thread and logs the reason' do
      Thread.current[:delayed_job_worker] = worker
      allow(Rails.logger).to receive(:error)

      expect(worker).to receive(:stop)
      SignalHandlerPlugin.stop_current_worker!('creds went bad')

      expect(Rails.logger).to have_received(:error).with(/stopping .*: creds went bad/)
    end

    it 'does nothing (and does not raise) when no worker is registered' do
      allow(Rails.logger).to receive(:error)
      expect { SignalHandlerPlugin.stop_current_worker!('no worker here') }.not_to raise_error
      expect(Rails.logger).not_to have_received(:error)
    end
  end
end

RSpec.describe AwsCredentialPreflightPlugin do
  let(:lifecycle) { Delayed::Lifecycle.new }
  let(:worker) { Delayed::Worker.new }
  let(:job_data) { { 'job_class' => 'BaseJob' } }
  let(:payload) { ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job_data) }
  let!(:dj_record) { Delayed::Job.create!(payload_object: payload) }
  let(:sts_client) { instance_double(Aws::STS::Client) }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_cache
  end

  before do
    # The plugin is off by default outside production/staging (AWS isn't reachable in
    # test), so force it on -- this whole describe block exists to test it.
    AwsCredentialPreflightPlugin.force_enabled = true
    # Reset the class-level health-check memoization so examples don't leak into each other.
    AwsCredentialPreflightPlugin.instance_variable_set(:@checked_at, nil)
    AwsCredentialPreflightPlugin.instance_variable_set(:@healthy, nil)
    allow(Aws::STS::Client).to receive(:new).and_return(sts_client)
    # Derive wiring order from the real Delayed::Worker.plugins list (rather than hand-typing
    # "Signal then Preflight") so that if the initializer's registration order ever regresses --
    # e.g. the two `Delayed::Worker.plugins <<` lines get swapped -- these specs feel it too,
    # instead of only the explicit order assertion below catching it.
    [SignalHandlerPlugin, AwsCredentialPreflightPlugin]
      .sort_by { |plugin| Delayed::Worker.plugins.index(plugin) }
      .each { |plugin| plugin.callback_block.call(lifecycle) }
  end

  after do
    Thread.current[:delayed_job_worker] = nil
    AwsCredentialPreflightPlugin.force_enabled = nil
  end

  describe '.enabled?' do
    it 'is disabled by default outside production/staging' do
      AwsCredentialPreflightPlugin.force_enabled = nil
      expect(AwsCredentialPreflightPlugin.enabled?).to be false
    end

    it 'skips the STS check entirely when disabled, and reports credentials as healthy' do
      AwsCredentialPreflightPlugin.force_enabled = nil
      expect(AwsCredentialPreflightPlugin.credentials_healthy?).to be true
      expect(Aws::STS::Client).not_to have_received(:new)
    end
  end

  describe '.credentials_healthy?' do
    it 'returns true when STS confirms the caller identity' do
      allow(sts_client).to receive(:get_caller_identity).and_return(double)
      expect(AwsCredentialPreflightPlugin.credentials_healthy?).to be true
    end

    it 'returns false when STS raises a recognized credential error, and alerts Sentry' do
      allow(Sentry).to receive(:capture_message)
      error_class = stub_const('Aws::STS::Errors::ExpiredTokenException', Class.new(StandardError))
      allow(sts_client).to receive(:get_caller_identity).and_raise(error_class.new('expired'))

      expect(AwsCredentialPreflightPlugin.credentials_healthy?).to be false

      # Alerting is how a human notices a live credential-rotation problem -- if this
      # silently stops firing, the fail-open/reschedule dance below has no visibility.
      expect(Sentry).to have_received(:capture_message).with(
        'AWS credential preflight check failed',
        level: :warning,
        extra: { error: 'Aws::STS::Errors::ExpiredTokenException', message: 'expired' },
      )
    end

    it 'fails open (returns true) when STS raises an unrelated error, and reports it to Sentry' do
      allow(Sentry).to receive(:capture_exception)
      error = Timeout::Error.new('slow')
      allow(sts_client).to receive(:get_caller_identity).and_raise(error)

      expect(AwsCredentialPreflightPlugin.credentials_healthy?).to be true

      expect(Sentry).to have_received(:capture_exception).with(error)
    end

    it 'caches the result and does not re-check STS again within the TTL' do
      allow(sts_client).to receive(:get_caller_identity).and_return(double)
      2.times { AwsCredentialPreflightPlugin.credentials_healthy? }
      expect(Aws::STS::Client).to have_received(:new).once
    end

    it 're-checks STS once the TTL has elapsed' do
      allow(sts_client).to receive(:get_caller_identity).and_return(double)
      AwsCredentialPreflightPlugin.credentials_healthy?
      # Simulate the TTL elapsing without sleeping the example -- back-date the memoized
      # check so the next call falls outside HEALTH_CHECK_TTL.
      stale_checked_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) - AwsCredentialPreflightPlugin::HEALTH_CHECK_TTL - 1
      AwsCredentialPreflightPlugin.instance_variable_set(:@checked_at, stale_checked_at)

      AwsCredentialPreflightPlugin.credentials_healthy?

      expect(Aws::STS::Client).to have_received(:new).twice
    end
  end

  describe '.preflight_reschedule_count' do
    it 'returns 0 when the job has never been deferred' do
      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(dj_record)).to eq(0)
    end

    it 'works for a plain (non-ActiveJob) payload with no job_data, unlike a payload-based counter' do
      plain_record = Delayed::Job.create!(payload_object: Object.new)

      AwsCredentialPreflightPlugin.reschedule!(plain_record, 1)

      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(plain_record)).to eq(1)
    end
  end

  describe '.reschedule!' do
    it 'clears the lock, delays run_at, and increments the safety counter' do
      dj_record.update!(locked_at: Time.current, locked_by: 'worker-1')

      AwsCredentialPreflightPlugin.reschedule!(dj_record, 1)
      dj_record.reload

      expect(dj_record.locked_at).to be_nil
      expect(dj_record.locked_by).to be_nil
      expect(dj_record.run_at).to be_within(1.second).of(Time.current + AwsCredentialPreflightPlugin::PREFLIGHT_RESCHEDULE_WAIT)
      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(dj_record)).to eq(1)
    end
  end

  describe 'callbacks' do
    it 'registers the plugin' do
      expect(Delayed::Worker.plugins).to include(AwsCredentialPreflightPlugin)
    end

    it 'registers after SignalHandlerPlugin in Delayed::Worker.plugins, so its around(:perform) ' \
       'callback nests inside SignalHandlerPlugin\'s and can see the thread-bound worker' do
      signal_index = Delayed::Worker.plugins.index(SignalHandlerPlugin)
      preflight_index = Delayed::Worker.plugins.index(AwsCredentialPreflightPlugin)

      expect(signal_index).not_to be_nil
      expect(preflight_index).not_to be_nil
      expect(signal_index).to be < preflight_index
    end

    it 'runs the job normally when credentials are healthy' do
      allow(sts_client).to receive(:get_caller_identity).and_return(double)
      ran = false

      lifecycle.run_callbacks(:perform, worker, dj_record) { ran = true }

      expect(ran).to be true
      expect(worker.stop?).to be false
    end

    it 'defers the job and stops the worker without running it, below the safety limit' do
      allow(sts_client).to receive(:get_caller_identity).and_raise(StandardError, 'bad creds')
      allow(AwsCredentialFailurePlugin).to receive(:credential_failure?).and_return(true)
      ran = false

      lifecycle.run_callbacks(:perform, worker, dj_record) { ran = true }

      expect(ran).to be false
      expect(worker.stop?).to be true
      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(dj_record)).to eq(1)
      dj_record.reload
      expect(dj_record.run_at).to be > Time.current
    end

    it 'lets the job run anyway once the safety counter is tripped, without recycling the pod or deferring further' do
      allow(Rails.logger).to receive(:error)
      AwsCredentialPreflightPlugin.reschedule!(dj_record, AwsCredentialPreflightPlugin::MAX_PREFLIGHT_RESCHEDULES)
      allow(sts_client).to receive(:get_caller_identity).and_raise(StandardError, 'bad creds')
      allow(AwsCredentialFailurePlugin).to receive(:credential_failure?).and_return(true)
      ran = false

      lifecycle.run_callbacks(:perform, worker, dj_record) { ran = true }

      expect(ran).to be true
      # The whole point of tripping the safety valve is to stop deferring and run
      # normally -- a stray reschedule!/stop_current_worker! call here would defeat that
      # and needlessly recycle the pod on every job while credentials stay broken.
      expect(worker.stop?).to be false
      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(dj_record)).to eq(AwsCredentialPreflightPlugin::MAX_PREFLIGHT_RESCHEDULES)
      expect(Rails.logger).to have_received(:error).with(/still unhealthy/)
    end

    it 'defers a plain (non-ActiveJob) payload the same as an ActiveJob one, and still trips the safety limit' do
      plain_record = Delayed::Job.create!(payload_object: Object.new)
      allow(sts_client).to receive(:get_caller_identity).and_raise(StandardError, 'bad creds')
      allow(AwsCredentialFailurePlugin).to receive(:credential_failure?).and_return(true)
      ran = false

      AwsCredentialPreflightPlugin::MAX_PREFLIGHT_RESCHEDULES.times do
        lifecycle.run_callbacks(:perform, worker, plain_record) { ran = true }
      end
      expect(ran).to be false
      expect(AwsCredentialPreflightPlugin.preflight_reschedule_count(plain_record)).to eq(AwsCredentialPreflightPlugin::MAX_PREFLIGHT_RESCHEDULES)

      lifecycle.run_callbacks(:perform, worker, plain_record) { ran = true }
      expect(ran).to be true
    end
  end
end

RSpec.describe AwsCredentialFailurePlugin do
  let(:lifecycle) { Delayed::Lifecycle.new }
  let(:payload) { ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new({}) }
  let(:job) { Delayed::Job.new(id: 789).tap { |j| j.payload_object = payload } }
  let(:worker) { Delayed::Worker.new }

  # Match the plugin's name-based detection without depending on the AWS SDK being loaded.
  let(:credential_error_class) { stub_const('Aws::STS::Errors::ExpiredTokenException', Class.new(StandardError)) }
  let(:credential_error) { credential_error_class.new('token expired') }

  before { AwsCredentialFailurePlugin.callback_block.call(lifecycle) }

  describe '.credential_failure?' do
    it 'recognizes every error name listed in CREDENTIAL_ERROR_NAMES' do
      # Guards against a typo or AWS SDK rename in any single entry: a bad name
      # silently disables detection for that error class and re-poisons the queue.
      AwsCredentialFailurePlugin::CREDENTIAL_ERROR_NAMES.each do |name|
        error_class = stub_const(name, Class.new(StandardError))
        expect(AwsCredentialFailurePlugin.credential_failure?(error_class.new('boom'))).
          to be(true), "expected #{name} to be recognized as a credential failure"
      end
    end

    it 'returns true when a recognized credential error is wrapped in the cause chain' do
      wrapped =
        begin
          begin
            raise credential_error
          rescue StandardError
            raise 'wrapping error'
          end
        rescue StandardError => e
          e
        end

      expect(wrapped).to be_a(RuntimeError)
      expect(wrapped.cause).to eq(credential_error)
      expect(AwsCredentialFailurePlugin.credential_failure?(wrapped)).to be true
    end

    it 'returns false for an unrelated error with no credential error in its cause chain' do
      expect(AwsCredentialFailurePlugin.credential_failure?(ArgumentError.new('nope'))).to be false
    end
  end

  describe 'callbacks' do
    # The credential plugin only catches and classifies the error; the actual stop happens
    # through SignalHandlerPlugin via the worker bound to the thread during :perform. Wire up
    # both plugins and nest the events the way Delayed::Worker does (invoke_job inside perform)
    # so the real cross-plugin hand-off is exercised rather than stubbed.
    before { SignalHandlerPlugin.callback_block.call(lifecycle) }

    it 'registers the plugin' do
      expect(Delayed::Worker.plugins).to include(AwsCredentialFailurePlugin)
    end

    it 'stops the worker bound during :perform and re-raises on a credential failure' do
      allow(Rails.logger).to receive(:error)

      expect do
        lifecycle.run_callbacks(:perform, worker, job) do
          lifecycle.run_callbacks(:invoke_job, job) { raise credential_error }
        end
      end.to raise_error(credential_error_class)

      expect(worker.stop?).to be true
      expect(Rails.logger).to have_received(:error).with(/AWS credential failure/)
    end

    it 'pushes attempts to the limit so a mid-flight credential failure is not retried' do
      allow(Rails.logger).to receive(:error)
      job.attempts = 0

      expect do
        lifecycle.run_callbacks(:perform, worker, job) do
          lifecycle.run_callbacks(:invoke_job, job) { raise credential_error }
        end
      end.to raise_error(credential_error_class)

      expect(job.attempts).to eq(Delayed::Worker.max_attempts)
    end

    it 're-raises non-credential errors without stopping the worker or touching attempts' do
      job.attempts = 0

      expect do
        lifecycle.run_callbacks(:perform, worker, job) do
          lifecycle.run_callbacks(:invoke_job, job) { raise ArgumentError, 'boom' }
        end
      end.to raise_error(ArgumentError, 'boom')

      expect(worker.stop?).to be false
      expect(job.attempts).to eq(0)
    end

    it 'does not interfere when the job succeeds' do
      ran = false

      lifecycle.run_callbacks(:perform, worker, job) do
        lifecycle.run_callbacks(:invoke_job, job) { ran = true }
      end

      expect(ran).to be true
      expect(worker.stop?).to be false
    end
  end
end

RSpec.describe DelayedJobJobIdProvider do
  let(:lifecycle) { Delayed::Lifecycle.new }
  let(:job) { Delayed::Job.new(id: 456) }
  let(:job_data) { { 'some' => 'data' } }
  let(:payload) { ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job_data) }

  before do
    job.payload_object = payload
    DelayedJobJobIdProvider.callback_block.call(lifecycle)
  end

  describe 'callbacks' do
    it 'registers the plugin' do
      expect(Delayed::Worker.plugins).to include(DelayedJobJobIdProvider)
    end

    it 'sets provider_job_id in job_data of ActiveJob JobWrapper' do
      lifecycle.run_callbacks(:invoke_job, job) { nil }
      expect(payload.job_data['provider_job_id']).to eq(456)
    end

    context 'when job_data is frozen' do
      let(:job_data) { { 'some' => 'data' }.freeze }

      it 'sets provider_job_id without mutating the frozen hash in place' do
        lifecycle.run_callbacks(:invoke_job, job) { nil }
        expect(payload.job_data['provider_job_id']).to eq(456)
      end
    end

    context 'when payload does not have job_data' do
      let(:payload) { Object.new }

      it 'does not raise error' do
        expect { lifecycle.run_callbacks(:invoke_job, job) { nil } }.not_to raise_error
      end
    end

    context 'when job_data is not a Hash' do
      let(:payload) { Struct.new(:job_data).new('not-a-hash') }

      it 'leaves the non-Hash payload untouched' do
        expect { lifecycle.run_callbacks(:invoke_job, job) { nil } }.not_to raise_error
        expect(payload.job_data).to eq('not-a-hash')
      end
    end
  end
end
