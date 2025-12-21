# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalHandlerPlugin do
  let(:worker) { double('Delayed::Worker') }
  let(:job) { double('Delayed::Job', id: 123) }
  let(:lifecycle) { Delayed::Lifecycle.new }

  before do
    SignalHandlerPlugin.registry.reset!
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
        active_workers = SignalHandlerPlugin.registry.all
        expect(active_workers[Thread.current]).to eq(worker)
      end

      # After performance, it should be unregistered
      active_workers = SignalHandlerPlugin.registry.all
      expect(active_workers).not_to have_key(Thread.current)
    end

    it 'unregisters the worker even if perform raises' do
      expect do
        lifecycle.run_callbacks(:perform, worker, job) { raise 'boom' }
      end.to raise_error('boom')

      active_workers = SignalHandlerPlugin.registry.all
      expect(active_workers).not_to have_key(Thread.current)
    end
  end

  describe '.current_worker_stopping?' do
    it 'returns true if the registered worker is stopping' do
      lifecycle.run_callbacks(:perform, worker, job) do
        allow(worker).to receive(:stop?).and_return(true)
        expect(SignalHandlerPlugin.current_worker_stopping?).to be true
      end
    end

    it 'returns false if the registered worker is not stopping' do
      lifecycle.run_callbacks(:perform, worker, job) do
        allow(worker).to receive(:stop?).and_return(false)
        expect(SignalHandlerPlugin.current_worker_stopping?).to be false
      end
    end

    it 'returns false if no worker is registered' do
      expect(SignalHandlerPlugin.current_worker_stopping?).to be false
    end
  end
end
