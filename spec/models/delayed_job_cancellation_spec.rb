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

    context 'when cancellation has not been requested' do
      it 'does not raise an exception' do
        expect { job.handle_cancellation! }.not_to raise_error
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

  describe '#interruptible?' do
    it 'delegates to JobDetail' do
      # JobDetail is initialized with the job, so we mock JobDetail.new(job)
      job_detail = instance_double(JobDetail, interruptible?: true)
      allow(JobDetail).to receive(:new).with(job).and_return(job_detail)

      expect(job.interruptible?).to be true
    end

    it 'returns false if JobDetail raises an error' do
      allow(JobDetail).to receive(:new).and_raise(StandardError)
      expect(job.interruptible?).to be false
    end
  end
end
