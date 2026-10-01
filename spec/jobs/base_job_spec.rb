###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseJob, type: :job do
  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :delayed_job
    example.run
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

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
    it 'defaults to 0 for idempotent jobs' do
      expect(job_instance.calculated_attempts).to eq(0)
    end

    context 'when the job is non-idempotent' do
      before do
        allow(job_instance).to receive(:supports_idempotent_retry?).and_return(false)
      end

      it 'returns a reduced count to limit retries' do
        max_dj_attempts = Delayed::Worker.max_attempts || 25
        expect(job_instance.calculated_attempts).to eq(max_dj_attempts - 1)
      end
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
        expect(new_job.attempts).to eq(job_instance.calculated_attempts)
        expect(new_job.locked_at).to be_nil
        expect(new_job.locked_by).to be_nil
        expect(new_job.failed_at).to be_nil
        expect(new_job.last_error).to be_nil
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

  describe 'retry behavior and initial attempts' do
    let(:max_attempts) { Delayed::Worker.max_attempts }

    # Using actual classes instead of stub_const for these because they need to be
    # reachable by the Delayed Job worker during perform_later integration tests.
    class IdempotentTestJob < BaseJob
      def perform
      end
    end

    class NonIdempotentTestJob < BaseJob
      def supports_idempotent_retry?
        false
      end

      def perform
      end
    end

    it 'sets attempts to 0 for idempotent jobs upon enqueue' do
      IdempotentTestJob.perform_later
      expect(Delayed::Job.last.attempts).to eq(0)
    end

    it 'sets reduced attempts for non-idempotent jobs upon enqueue' do
      NonIdempotentTestJob.perform_later
      expect(Delayed::Job.last.attempts).to eq(max_attempts - 1)
    end
  end

  describe '.record_dj_metrics?' do
    # This gate decides whether the hooks below are wired up at all, and it has to agree
    # with the ENABLE_DJ_METRICS branch in docker/app/entrypoint.sh that starts the
    # exporter. Recording on a container with no exporter writes metrics nothing reads.
    def with_env(vars)
      stub_const('ENV', ENV.to_h.merge(vars))
    end

    it 'records on a delayed job worker with the exporter enabled' do
      with_env('CONTAINER_VARIANT' => 'dj', 'ENABLE_DJ_METRICS' => 'true')

      expect(described_class.record_dj_metrics?).to be true
    end

    it 'does not record on a dj container with the exporter turned off' do
      with_env('CONTAINER_VARIANT' => 'dj', 'ENABLE_DJ_METRICS' => 'false')

      expect(described_class.record_dj_metrics?).to be false
    end

    it 'does not record on a web container' do
      with_env('CONTAINER_VARIANT' => 'web', 'ENABLE_DJ_METRICS' => 'true')

      expect(described_class.record_dj_metrics?).to be false
    end

    it 'does not record on a cron container, which sets no variant' do
      stub_const('ENV', ENV.to_h.except('CONTAINER_VARIANT').merge('ENABLE_DJ_METRICS' => 'true'))

      expect(described_class.record_dj_metrics?).to be false
    end

    it 'does not record in development or test, where neither variable is set' do
      stub_const('ENV', ENV.to_h.except('CONTAINER_VARIANT', 'ENABLE_DJ_METRICS'))

      expect(described_class.record_dj_metrics?).to be false
    end
  end

  # The hooks that call these are only wired up when .record_dj_metrics? is true, so the
  # handlers are exercised directly here.
  describe 'delayed job metric handlers' do
    let(:status_metric) { instance_double(Prometheus::Client::Counter, increment: nil) }
    let(:run_length_metric) { instance_double(Prometheus::Client::Histogram, observe: nil) }

    before do
      allow(DjMetrics.instance).to receive(:dj_job_status_total_metric).and_return(status_metric)
      allow(DjMetrics.instance).to receive(:dj_job_run_length_seconds_metric).and_return(run_length_metric)
    end

    describe '#before_handler' do
      it 'counts the job as started and records when it started' do
        job_instance.before_handler(job_instance)

        expect(status_metric).to have_received(:increment).
          with(labels: { queue: job_instance.queue_name, priority: job_instance.priority, status: 'started', job_name: job_class.name })
        expect(job_instance.start_time).to be_present
      end
    end

    describe '#after_handler' do
      before do
        job_instance.start_time = 30.seconds.ago
      end

      it 'counts the job as successful and observes how long it ran' do
        job_instance.after_handler(job_instance)

        expect(status_metric).to have_received(:increment).
          with(labels: { queue: job_instance.queue_name, priority: job_instance.priority, status: 'success', job_name: job_class.name })
        expect(run_length_metric).to have_received(:observe).
          with(a_value_within(5).of(30), labels: { job_name: job_class.name })
      end
    end

    describe '#job_queue_name' do
      it 'uses queue_name when handed an ActiveJob instance' do
        expect(job_instance.send(:job_queue_name, job_instance)).to eq(job_instance.queue_name)
      end

      it 'falls back to queue when handed a Delayed::Job record' do
        dj_record = Delayed::Job.create!(handler: 'dummy', queue: 'long_running')

        expect(job_instance.send(:job_queue_name, dj_record)).to eq('long_running')
      end
    end
  end
end
