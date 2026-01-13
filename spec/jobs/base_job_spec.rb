# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseJob, type: :job do
  let(:job_class) do
    stub_const('TestBaseJob', Class.new(described_class) do
      def perform
      end
    end)
  end
  let(:job_instance) { job_class.new }
  let(:aj_uuid) { SecureRandom.uuid }

  before do
    allow(job_instance).to receive(:job_id).and_return(aj_uuid)
  end

  describe '#calculated_attempts' do
    it 'defaults to 0' do
      expect(job_instance.calculated_attempts).to eq(0)
    end
  end

  describe '#delayed_job' do
    context 'when provider_job_id is present' do
      let!(:dj_record) { Delayed::Job.create!(handler: 'dummy') }

      before do
        allow(job_instance).to receive(:provider_job_id).and_return(dj_record.id)
      end

      it 'returns the job record using provider_job_id' do
        expect(job_instance.delayed_job).to eq(dj_record)
      end
    end

    context 'when provider_job_id is missing' do
      let!(:dj_record) { Delayed::Job.create!(handler: "--- !ruby/object:ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper\njob_data:\n  job_id: #{aj_uuid}\n") }

      before do
        allow(job_instance).to receive(:provider_job_id).and_return(nil)
      end

      it 'falls back to searching the handler column for the ActiveJob UUID' do
        expect(job_instance.delayed_job).to eq(dj_record)
      end
    end

    context 'when no record can be found' do
      it 'returns nil' do
        expect(job_instance.delayed_job).to be_nil
      end
    end
  end

  describe '#requeue_at' do
    let(:timestamp) { 10.minutes.from_now }
    let(:message) { 'Requeuing for collision' }

    context 'when the job record exists' do
      let!(:dj_record) do
        Delayed::Job.create!(
          handler: 'dummy',
          attempts: 1,
          failed_at: Time.current,
          last_error: 'Some error',
          locked_at: Time.current,
          locked_by: 'worker-1',
        )
      end

      before do
        allow(job_instance).to receive(:provider_job_id).and_return(dj_record.id)
      end

      it 'duplicates the job and schedules it for the future with cleared metadata' do
        original_id = dj_record.id
        expect do
          job_instance.requeue_at(timestamp, message)
        end.to change(Delayed::Job, :count).by(1)

        new_job = Delayed::Job.last
        expect(new_job.id).not_to eq(original_id)
        expect(new_job.run_at.to_i).to eq(timestamp.to_i)
        expect(new_job.attempts).to eq(0)
        expect(new_job.locked_at).to be_nil
        expect(new_job.locked_by).to be_nil
        expect(new_job.failed_at).to be_nil
        expect(new_job.last_error).to be_nil

        # Verify original record remains unchanged
        dj_record.reload
        expect(dj_record.failed_at).not_to be_nil
        expect(dj_record.last_error).to eq('Some error')
      end

      it 'logs the provided message' do
        allow(Rails.logger).to receive(:info)
        job_instance.requeue_at(timestamp, message)
        expect(Rails.logger).to have_received(:info).with(message)
      end
    end

    context 'when the job record is missing' do
      before do
        allow(job_instance).to receive(:provider_job_id).and_return(999_999)
        allow(Sentry).to receive(:capture_message)
      end

      it 'notifies Sentry and returns silently' do
        expect do
          job_instance.requeue_at(timestamp, message)
        end.not_to raise_error

        expect(Sentry).to have_received(:capture_message).with(
          /Unable to find delayed_job for requeue_at in TestBaseJob/,
        )
      end
    end
  end
end
