###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationJob do
  let(:job_class) do
    stub_const('InterruptTestJob', Class.new(described_class) do
      queue_as :__sigterm_test__

      def perform
        raise ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM'
      end
    end)
  end

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :delayed_job
    example.run
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  it 're-enqueues interrupted jobs without marking failure' do
    Delayed::Job.delete_all
    job = job_class.perform_later

    worker = Delayed::Worker.new(queues: ['__sigterm_test__'])
    successes, failures = worker.work_off

    expect(successes).to eq(1)
    expect(failures).to eq(0)
    expect(Delayed::Job.exists?(job.provider_job_id)).to be false

    # A new job should have been enqueued by retry_job and scheduled for later
    new_job = Delayed::Job.where(queue: '__sigterm_test__').first
    expect(new_job).to be_present
    expect(new_job.run_at).to be > 10.seconds.from_now
  end

  describe 'BaseJob subclasses with DJ metrics enabled' do
    let(:failure_metric) { double('counter', increment: nil) }
    let(:worker) { Delayed::Worker.new(queues: ['__sigterm_test__']) }

    before do
      Delayed::Job.delete_all
      allow(BaseJob).to receive(:record_dj_metrics?).and_return(true)
      allow(DjMetrics).to receive(:instance).and_return(double('dj_metrics', dj_job_status_total_metric: failure_metric))
    end

    def queued_job_classes
      Delayed::Job.where(queue: '__sigterm_test__').map { |dj| dj.payload_object.job_data['job_class'] }
    end

    it 're-enqueues interrupted jobs without counting a failure' do
      stub_const('BaseInterruptTestJob', Class.new(BaseJob) do
        queue_as :__sigterm_test__

        def perform
          raise ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM'
        end
      end)
      BaseInterruptTestJob.perform_later

      successes, failures = worker.work_off

      expect([successes, failures]).to eq([1, 0])
      expect(queued_job_classes).to eq(['BaseInterruptTestJob'])
      expect(failure_metric).not_to have_received(:increment)
    end

    it 'counts genuine failures and lets them fail the job' do
      stub_const('BaseFailureTestJob', Class.new(BaseJob) do
        queue_as :__sigterm_test__

        def perform
          raise ArgumentError, 'boom'
        end
      end)
      BaseFailureTestJob.perform_later

      _successes, failures = worker.work_off

      expect(failures).to eq(1)
      expect(failure_metric).to have_received(:increment).with(labels: hash_including(status: 'failure', job_name: 'BaseFailureTestJob'))
    end

    it 're-enqueues the outer job when a job it runs with perform_now is interrupted' do
      stub_const('NestedInnerTestJob', Class.new(BaseJob) do
        def perform
          raise ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM'
        end
      end)
      stub_const('NestedOuterTestJob', Class.new(BaseJob) do
        queue_as :__sigterm_test__
        cattr_accessor :finished

        def perform
          NestedInnerTestJob.perform_now
          self.class.finished = true
        end
      end)
      NestedOuterTestJob.perform_later

      successes, failures = worker.work_off

      expect([successes, failures]).to eq([1, 0])
      expect(NestedOuterTestJob.finished).to be_nil
      expect(queued_job_classes).to eq(['NestedOuterTestJob'])
    end

    it 'alerts once a job has been interrupted repeatedly' do
      allow(Sentry).to receive(:capture_message)
      stub_const('RepeatInterruptTestJob', Class.new(BaseJob) do
        queue_as :__sigterm_test__

        def perform
          raise ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM'
        end
      end)
      job = RepeatInterruptTestJob.new
      job.provider_job_id = 1
      job.executions = ApplicationJob::INTERRUPTION_ALERT_THRESHOLD - 1

      job.perform_now

      expect(Sentry).to have_received(:capture_message).with(/RepeatInterruptTestJob interrupted 3 times/, anything)
      expect(queued_job_classes).to eq(['RepeatInterruptTestJob'])
    end
  end

  describe '#check_halt_status!' do
    let(:job_class) do
      stub_const('HaltTestJob', Class.new(described_class) do
        def perform
        end
      end)
    end
    let(:job_instance) { job_class.new }
    let(:dj_record) { Delayed::Job.create!(handler: job_instance.to_yaml) }

    before do
      allow(job_instance).to receive(:provider_job_id).and_return(dj_record.id)
      allow(job_class).to receive(:queue_adapter_name).and_return('delayed_job')
    end

    context 'when cancellation has been requested' do
      before do
        dj_record.update!(cancellation_requested_at: Time.current)
      end

      it 'raises a JobCancelled exception' do
        expect { job_instance.check_halt_status! }.to raise_error(ApplicationJob::JobCancelled, /Job .* cancelled/)
      end
    end

    context 'when sigterm has been received' do
      before do
        allow(SignalHandlerPlugin).to receive(:current_worker_stopping?).and_return(true)
      end

      it 'raises a JobInterrupted exception' do
        expect { job_instance.check_halt_status! }.to raise_error(ApplicationJob::JobInterrupted, 'Job interrupted by SIGTERM')
      end
    end
  end
end
