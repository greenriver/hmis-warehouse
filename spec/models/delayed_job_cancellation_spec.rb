# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Delayed::Backend::ActiveRecord::Job, type: :model do
  let(:job) { described_class.create!(handler: 'some_handler') }

  describe '#check_halt_status!' do
    context 'when cancellation has been requested' do
      before do
        job.update!(cancellation_requested_at: Time.current)
      end

      it 'raises a JobCancelled exception' do
        expect { job.check_halt_status! }.to raise_error(ApplicationJob::JobCancelled, 'Job cancelled')
      end
    end

    context 'when sigterm has been received' do
      before do
        allow(SignalHandlerPlugin).to receive(:current_worker_stopping?).and_return(true)
      end

      it 'raises a JobInterrupted exception' do
        expect { job.check_halt_status! }.to raise_error(ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM')
      end
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
