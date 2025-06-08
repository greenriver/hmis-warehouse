# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaintenanceTaskInstrumentation, type: :job do
  # Create a test job class that includes the concern
  let(:test_job_class) do
    Class.new(BaseJob) do
      include MaintenanceTaskInstrumentation

      def self.name
        'TestInstrumentedJob'
      end

      def perform(should_fail: false)
        instrument_as_maintenance_task(job: self, name: 'perform') do |run|
          raise StandardError, 'Test failure' if should_fail

          run.record_success!
        end
      end
    end
  end

  let(:job) { test_job_class.new }

  describe 'successful job execution' do
    it 'creates a maintenance task record' do
      expect do
        job.perform
      end.to change(GrdaWarehouse::Tasks::SystemMaintenanceTask, :count).by(1)

      task = GrdaWarehouse::Tasks::SystemMaintenanceTask.last
      expect(task.name).to eq('perform')
      expect(task.job_type).to eq('TestInstrumentedJob')
    end

    it 'creates a task run record with completion time' do
      freeze_time do
        job.perform

        task = GrdaWarehouse::Tasks::SystemMaintenanceTask.last
        run = task.system_maintenance_task_runs.last

        expect(run.started_at).to eq(Time.current)
        expect(run.completed_at).to eq(Time.current)
      end
    end

    it 'reuses existing task record on subsequent runs' do
      job.perform

      expect do
        job.perform
      end.not_to change(GrdaWarehouse::Tasks::SystemMaintenanceTask, :count)

      task = GrdaWarehouse::Tasks::SystemMaintenanceTask.last
      expect(task.system_maintenance_task_runs.count).to eq(2)
    end
  end

  describe 'failed job execution' do
    it 'creates task run without completion time when job fails' do
      freeze_time do
        expect do
          job.perform(should_fail: true)
        end.to raise_error(StandardError, 'Test failure')

        task = GrdaWarehouse::Tasks::SystemMaintenanceTask.last
        run = task.system_maintenance_task_runs.last

        expect(run.started_at).to eq(Time.current)
        expect(run.completed_at).to be_nil
      end
    end
  end
end
