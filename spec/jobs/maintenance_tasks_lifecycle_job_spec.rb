# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaintenanceTasksLifecycleJob, type: :job do
  let(:job) { described_class.new }

  describe '#perform' do
    it 'processes alerts for all existing tasks' do
      # Create tasks with unique names
      task1 = create(:system_maintenance_task, name: 'Importing::RunDailyImportsJob')
      task2 = create(:system_maintenance_task, name: 'SomeOtherJob')

      # Update both tasks to have short thresholds and old runs
      task1.update!(completion_alert_minutes: 60)
      task2.update!(completion_alert_minutes: 60)

      # Create old runs that exceed the threshold for both tasks
      create(:system_maintenance_task_run,
             system_maintenance_task: task1,
             started_at: 2.hours.ago,
             completed_at: 2.hours.ago)
      create(:system_maintenance_task_run,
             system_maintenance_task: task2,
             started_at: 2.hours.ago,
             completed_at: 2.hours.ago)

      # Mock Sentry to verify alerts are sent
      allow(Sentry).to receive(:capture_message)

      job.perform

      # Verify that alerts were sent for both tasks
      expect(Sentry).to have_received(:capture_message).with(a_string_matching(/Exceeded threshold/)).at_least(2).times
    end

    it 'deletes expired task runs for all jobs' do
      task1 = create(:system_maintenance_task, name: 'Importing::RunDailyImportsJob')
      task2 = create(:system_maintenance_task, name: 'SomeOtherJob')

      # Create recent and expired runs
      recent_run = create(:system_maintenance_task_run, system_maintenance_task: task1, started_at: 1.month.ago)
      expired_run1 = create(:system_maintenance_task_run, system_maintenance_task: task1, started_at: 7.months.ago)
      expired_run2 = create(:system_maintenance_task_run, system_maintenance_task: task2, started_at: 7.months.ago)

      job.perform

      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(recent_run.id)).to be true
      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(expired_run1.id)).to be false
      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(expired_run2.id)).to be false
    end
  end
end
