# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalHandlerPlugin do
  let(:worker) { double('Delayed::Worker') }
  let(:job) { double('Delayed::Job', id: 123) }
  let(:lifecycle) { Delayed::Lifecycle.new }

  before do
    SignalHandlerPlugin.reset!
    # Apply the plugin callbacks to our test lifecycle
    SignalHandlerPlugin.callback_block.call(lifecycle)
  end

  describe 'callbacks' do
    it 'registers the plugin' do
      expect(Delayed::Worker.plugins).to include(SignalHandlerPlugin)
    end

    it 'registers the worker in the registry during performance' do
      lifecycle.run_callbacks(:perform, worker, job) do
        # Within the perform block, the worker should be registered
        SignalHandlerPlugin.registry_mutex.synchronize do
          active_workers = SignalHandlerPlugin.instance_variable_get(:@active_workers)
          # rubocop:disable Lint/HashCompareByIdentity
          expect(active_workers[Thread.current.object_id]).to eq(worker)
          # rubocop:enable Lint/HashCompareByIdentity
        end
      end

      # After performance, it should be unregistered
      SignalHandlerPlugin.registry_mutex.synchronize do
        active_workers = SignalHandlerPlugin.instance_variable_get(:@active_workers)
        expect(active_workers).not_to have_key(Thread.current.object_id)
      end
    end
  end

  describe '.current_worker_stopping?' do
    it 'returns true if the registered worker has @exit set to true' do
      lifecycle.run_callbacks(:perform, worker, job) do
        worker.instance_variable_set(:@exit, true)
        expect(SignalHandlerPlugin.current_worker_stopping?).to be true
      end
    end

    it 'returns false if the registered worker has @exit set to false' do
      lifecycle.run_callbacks(:perform, worker, job) do
        worker.instance_variable_set(:@exit, false)
        expect(SignalHandlerPlugin.current_worker_stopping?).to be false
      end
    end

    it 'returns false if no worker is registered' do
      expect(SignalHandlerPlugin.current_worker_stopping?).to be false
    end
  end
end
