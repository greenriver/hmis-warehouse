# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalHandlerPlugin do
  let(:worker) { double('Delayed::Worker') }
  let(:job) { double('Delayed::Job', id: 123) }
  let(:lifecycle) { Delayed::Lifecycle.new }

  before do
    # Clear thread-local storage before each test
    Thread.current[:delayed_job_worker] = nil
    # Apply the plugin callbacks to our test lifecycle
    SignalHandlerPlugin.callback_block.call(lifecycle)
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
