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

RSpec.describe AwsCredentialFailurePlugin do
  let(:lifecycle) { Delayed::Lifecycle.new }
  let(:job) { Delayed::Job.new(id: 789) }
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

    it 're-raises non-credential errors without stopping the worker' do
      expect do
        lifecycle.run_callbacks(:perform, worker, job) do
          lifecycle.run_callbacks(:invoke_job, job) { raise ArgumentError, 'boom' }
        end
      end.to raise_error(ArgumentError, 'boom')

      expect(worker.stop?).to be false
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
