# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignalHandlerPlugin do
  let(:worker) { double('Delayed::Worker', stop: nil) }
  let(:job) { double('Delayed::Job', id: 123) }
  let(:lifecycle) { Delayed::Lifecycle.new }

  before do
    # Clear state before each test
    SignalHandlerPlugin.interrupted_job_id = nil
    SignalHandlerPlugin.previous_trap = nil

    # Apply the plugin callbacks to our test lifecycle
    SignalHandlerPlugin.callback_block.call(lifecycle)
  end

  describe 'callbacks' do
    it 'registers before and after perform callbacks' do
      # This is a bit internal to Delayed Job, but we want to ensure our plugin is active
      expect(Delayed::Worker.plugins).to include(SignalHandlerPlugin)
    end

    describe 'TERM signal trapping' do
      let(:trap_block) { [] }

      before do
        # Mock Signal.trap to capture the block being registered
        # and support returning a value. Allow any arguments.
        allow(Signal).to receive(:trap).with('TERM', any_args) do |*args, &block|
          trap_block << block if block
          'PREVIOUS_HANDLER'
        end
      end

      it 'sets up a trap before perform and restores it after' do
        # 1. Trigger before_perform
        lifecycle.run_callbacks(:perform, worker, job) do
          expect(Signal).to have_received(:trap).with('TERM')
          expect(SignalHandlerPlugin.previous_trap).to eq('PREVIOUS_HANDLER')

          # 2. Simulate the signal being received
          trap_block.first.call

          expect(SignalHandlerPlugin.interrupted_job_id).to eq(job.id)
          expect(worker).to have_received(:stop)
        end

        # 3. Trigger after_perform cleanup
        expect(Signal).to have_received(:trap).with('TERM', 'PREVIOUS_HANDLER')
        expect(SignalHandlerPlugin.interrupted_job_id).to be_nil
        expect(SignalHandlerPlugin.previous_trap).to be_nil
      end

      it 'calls the previous handler if it was a proc' do
        previous_proc = double('proc', call: nil)
        # Override the return value but keep the block capture
        allow(Signal).to receive(:trap).with('TERM', any_args) do |*args, &block|
          trap_block << block if block
          previous_proc
        end

        lifecycle.run_callbacks(:perform, worker, job) do
          trap_block.first.call
          expect(previous_proc).to have_received(:call)
        end
      end
    end
  end
end
