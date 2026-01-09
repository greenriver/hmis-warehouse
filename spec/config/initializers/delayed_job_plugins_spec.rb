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

      it 'successfully sets provider_job_id without error' do
        expect { lifecycle.run_callbacks(:invoke_job, job) { nil } }.not_to raise_error
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

      it 'does not raise error' do
        expect { lifecycle.run_callbacks(:invoke_job, job) { nil } }.not_to raise_error
      end
    end
  end
end
