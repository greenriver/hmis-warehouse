# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Delayed::Backend::ActiveRecord::Job, type: :model do
  let(:job) { described_class.create!(handler: 'some_handler') }

  describe '#handle_cancellation!' do
    context 'when cancellation has been requested' do
      before do
        job.update!(cancellation_requested_at: Time.current)
      end

      it 'raises a JobCancelled exception' do
        expect { job.handle_cancellation! }.to raise_error(ApplicationJob::JobCancelled, 'Job cancelled')
      end
    end

    context 'when sigterm has been received' do
      before do
        allow(job).to receive(:sigterm_received?).and_return(true)
      end

      it 'raises a JobRetried exception' do
        expect { job.handle_cancellation! }.to raise_error(ApplicationJob::JobRetried, 'SIGTERM caught, retrying')
      end
    end
  end

  describe '#sigterm_received?' do
    let(:job_id) { 123 }
    before { allow(job).to receive(:id).and_return(job_id) }

    it 'is true if SignalHandlerPlugin.interrupted_job_id matches job id' do
      allow(SignalHandlerPlugin).to receive(:interrupted_job_id).and_return(job_id)
      expect(job.sigterm_received?).to be true
    end

    it 'is false if SignalHandlerPlugin.interrupted_job_id does not match job id' do
      allow(SignalHandlerPlugin).to receive(:interrupted_job_id).and_return(456)
      expect(job.sigterm_received?).to be false
    end

    it 'is false if SignalHandlerPlugin.interrupted_job_id is nil' do
      allow(SignalHandlerPlugin).to receive(:interrupted_job_id).and_return(nil)
      expect(job.sigterm_received?).to be false
    end
  end

  describe '#cancellable?' do
    it 'is true if the job has not started' do
      job.update!(locked_at: nil)
      expect(job.cancellable?).to be true
    end

    it 'is false if cancellation has already been requested' do
      job.update!(cancellation_requested_at: Time.current)
      expect(job.cancellable?).to be false
    end

    it 'is false if the job has already failed' do
      job.update!(failed_at: Time.current)
      expect(job.cancellable?).to be false
    end

    context 'when the job is running' do
      before do
        job.update!(locked_at: Time.current, locked_by: 'worker')
      end

      it 'is true if the job is interruptible' do
        allow(job).to receive(:interruptible?).and_return(true)
        expect(job.cancellable?).to be true
      end

      it 'is false if the job is not interruptible' do
        allow(job).to receive(:interruptible?).and_return(false)
        expect(job.cancellable?).to be false
      end
    end
  end

  describe '#requeueable?' do
    it 'is true if the job has failed' do
      job.update!(failed_at: Time.current)
      expect(job.requeueable?).to be true
    end

    it 'is true if cancellation has been requested' do
      job.update!(cancellation_requested_at: Time.current)
      expect(job.requeueable?).to be true
    end

    it 'is false if the job is just pending' do
      job.update!(failed_at: nil, cancellation_requested_at: nil)
      expect(job.requeueable?).to be false
    end
  end
end
