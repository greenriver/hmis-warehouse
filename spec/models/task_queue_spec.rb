###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskQueue, '.register_tasks' do
  let(:config) { Rails.application.config }

  before { described_class.register_tasks(config) }

  it 'registers a single importer_log_id/DateUpdated index task' do
    expect(config.queued_tasks.keys).to include(:hmis_csv_2026_importer_log_id_date_updated_index)
  end

  it 'calls ensure_importer_log_id_date_updated_index! on every base FY2026 importer class except Export, sequentially' do
    expected_classes = HmisCsvTwentyTwentySix.base_importable_files_map.except('Export.csv').values.map do |name|
      HmisCsvTwentyTwentySix.data_lake_file_class(name, 'Importer')
    end

    expected_classes.each { |klass| expect(klass).to receive(:ensure_importer_log_id_date_updated_index!) }
    expect(HmisCsvTwentyTwentySix::Importer::Export).not_to receive(:ensure_importer_log_id_date_updated_index!)

    config.queued_tasks[:hmis_csv_2026_importer_log_id_date_updated_index].call
  end
end

RSpec.describe TaskQueue, '#run!' do
  it 'clears queued_at for an unrecognized key instead of raising, so the cron re-queues it' do
    task = TaskQueue.create!(task_key: :not_a_registered_task, queued_at: 1.hour.ago)

    expect { task.run! }.not_to raise_error
    expect(task.reload.queued_at).to be_nil
    expect(task.active).to be true
    expect(task.started_at).to be_nil
  end

  it 'leaves re-queuing an unrecognized key to the cron rather than enqueuing a job itself' do
    task = TaskQueue.create!(task_key: :not_a_registered_task, queued_at: Time.current)
    allow(task).to receive(:delay).and_return(double(run!: true))

    task.run!

    expect(task).not_to have_received(:delay)
  end

  it 'gives up on an unrecognized key once the row is old enough to be stalled' do
    allow(Sentry).to receive(:capture_message)
    task = TaskQueue.create!(task_key: :not_a_registered_task, created_at: 3.days.ago, queued_at: 1.hour.ago)
    allow(task).to receive(:delay).and_return(double(run!: true))

    task.run!

    expect(task).not_to have_received(:delay)
    expect(task.reload.active).to be false
    # left queued so the abandoned row is distinguishable from one waiting to be picked up
    expect(task.queued_at).to be_present
    expect(Sentry).to have_received(:capture_message).
      with(/not_a_registered_task/, hash_including(level: :warning, extra: { task_id: task.id }))
  end

  it 'does not alert while an unrecognized key is still being re-queued' do
    allow(Sentry).to receive(:capture_message)
    task = TaskQueue.create!(task_key: :not_a_registered_task, queued_at: 1.hour.ago)

    task.run!

    expect(Sentry).not_to have_received(:capture_message)
    expect(task.reload.active).to be true
  end

  it 'runs a registered task and records that it started and completed' do
    ran = false
    allow(TaskQueue).to receive(:available_tasks).and_return(a_known_task: -> { ran = true })
    task = TaskQueue.create!(task_key: :a_known_task, queued_at: Time.current)

    task.run!

    expect(ran).to be true
    expect(task.reload.started_at).to be_present
    expect(task.completed_at).to be_present
  end

  it 'lets a failure bubble to Delayed Job, leaving the row incomplete and still queued' do
    allow(TaskQueue).to receive(:available_tasks).and_return(a_known_task: -> { raise 'boom' })
    task = TaskQueue.create!(task_key: :a_known_task, queued_at: Time.current)

    expect { task.run! }.to raise_error('boom')
    expect(task.reload.completed_at).to be_nil
    expect(task.queued_at).to be_present
  end
end

RSpec.describe TaskQueue, '.queue_unprocessed!' do
  let(:delay_proxy) { double(run!: true) }

  before do
    allow(TaskQueue).to receive(:available_tasks).and_return(a_known_task: -> {})
    allow_any_instance_of(TaskQueue).to receive(:delay).and_return(delay_proxy)
    allow(Sentry).to receive(:capture_message)
  end

  it 'creates and queues a row when the key has none' do
    described_class.queue_unprocessed!

    task = TaskQueue.find_by(task_key: 'a_known_task')
    expect(task.queued_at).to be_present
    expect(delay_proxy).to have_received(:run!)
  end

  it 're-queues an existing unqueued row instead of creating a second one' do
    task = TaskQueue.create!(task_key: :a_known_task)

    expect { described_class.queue_unprocessed! }.not_to change(TaskQueue, :count)
    expect(task.reload.queued_at).to be_present
    expect(delay_proxy).to have_received(:run!)
  end

  it 're-queues the same row that run! handed back for an unrecognized key' do
    task = TaskQueue.create!(task_key: :a_known_task, queued_at: 1.hour.ago)
    # Stand in for a worker on older code that doesn't have the key registered
    allow(TaskQueue).to receive(:available_tasks).and_return({})
    task.run!
    expect(task.reload.queued_at).to be_nil
    allow(TaskQueue).to receive(:available_tasks).and_return(a_known_task: -> {})

    expect { described_class.queue_unprocessed! }.not_to change(TaskQueue, :count)
    expect(task.reload.queued_at).to be_present
    expect(delay_proxy).to have_received(:run!).once
  end

  it 'queues a fresh row for a key whose previous row was abandoned as stalled' do
    abandoned = TaskQueue.create!(task_key: :a_known_task, created_at: 3.days.ago, queued_at: 1.hour.ago)
    allow(TaskQueue).to receive(:available_tasks).and_return({})
    abandoned.run!
    expect(abandoned.reload.active).to be false
    allow(TaskQueue).to receive(:available_tasks).and_return(a_known_task: -> {})

    expect { described_class.queue_unprocessed! }.to change(TaskQueue, :count).by(1)
    expect(delay_proxy).to have_received(:run!).once
  end

  it 'runs a key whose newest row was never queued, however old that row is' do
    old = TaskQueue.create!(task_key: :a_known_task, created_at: 2.years.ago)

    expect { described_class.queue_unprocessed! }.not_to change(TaskQueue, :count)
    expect(old.reload.queued_at).to be_present
    expect(delay_proxy).to have_received(:run!)
  end

  it 'leaves a queued, incomplete row alone without bumping queued_at' do
    queued_at = 1.hour.ago
    task = TaskQueue.create!(task_key: :a_known_task, queued_at: queued_at)

    described_class.queue_unprocessed!

    expect(task.reload.queued_at).to be_within(1.second).of(queued_at)
    expect(delay_proxy).not_to have_received(:run!)
  end

  it 'ignores an inactive row and queues a fresh one for the key' do
    TaskQueue.create!(task_key: :a_known_task, queued_at: Time.current, active: false)

    expect { described_class.queue_unprocessed! }.to change(TaskQueue, :count).by(1)
    expect(delay_proxy).to have_received(:run!)
  end

  it 'leaves a long-queued, incomplete row alone; run! owns deciding it is stalled' do
    task = TaskQueue.create!(task_key: :a_known_task, queued_at: 3.days.ago)

    described_class.queue_unprocessed!

    expect(Sentry).not_to have_received(:capture_message)
    expect(delay_proxy).not_to have_received(:run!)
    expect(task.reload.active).to be true
  end

  it 'does not re-queue an old row that completed' do
    TaskQueue.create!(task_key: :a_known_task, queued_at: 3.days.ago, completed_at: 3.days.ago)

    described_class.queue_unprocessed!

    expect(delay_proxy).not_to have_received(:run!)
  end
end
