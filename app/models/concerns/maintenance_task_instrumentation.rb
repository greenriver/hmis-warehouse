# frozen_string_literal: true

module MaintenanceTaskInstrumentation
  extend ActiveSupport::Concern

  protected

  def instrument_as_maintenance_task(job:, name:, alert_threshold_minutes: (60 * 36), &block)
    task = find_or_create_maintenance_task(job: job, name: name, alert_threshold_minutes: alert_threshold_minutes)
    run = task.system_maintenance_task_runs.create!(started_at: Time.current)
    block.call(run)
    # if the run completed, clear alert-sent to it will trigger in the future
    task.update!(alert_sent_at: nil) if run.completed?
  end

  def find_or_create_maintenance_task(job:, name:, alert_threshold_minutes: (60 * 36))
    task = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(job_type: job.class.name, name: name).first_or_initialize
    task.alert_threshold_minutes = alert_threshold_minutes
    task.save! if task.changed?
    task
  end
end
