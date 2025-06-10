# frozen_string_literal: true

class GrdaWarehouse::Tasks::TaskInstrumentation
  include Singleton

  def call(job:, name:, completion_alert_minutes: (60 * 36), &block)
    task = find_or_create_maintenance_task(job: job, name: name, completion_alert_minutes: completion_alert_minutes)
    run = task.system_maintenance_task_runs.create!(started_at: Time.current)
    block.call(run)
    # if the run completed, clear alert-sent to it will trigger in the future
    task.update!(alert_sent_at: nil) if run.completed?
  end

  protected

  def find_or_create_maintenance_task(job:, name:, completion_alert_minutes: (60 * 36))
    task = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(job_type: job.class.name, name: name).first_or_initialize
    task.completion_alert_minutes = completion_alert_minutes
    task.save! if task.changed?
    task
  end
end
