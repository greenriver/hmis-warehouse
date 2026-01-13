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
