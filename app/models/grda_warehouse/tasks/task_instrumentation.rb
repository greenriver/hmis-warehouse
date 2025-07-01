# frozen_string_literal: true

require 'memory_profiler'
class GrdaWarehouse::Tasks::TaskInstrumentation
  include Singleton

  # convenience method
  def self.call(...) = instance.call(...)

  def call(name, alert_threshold:, &block)
    task = find_or_create_maintenance_task(name, alert_threshold: alert_threshold)
    run = task.system_maintenance_task_runs.create!(started_at: Time.current)
    profile = AppConfigProperty.where(key: 'profile_system_maintenance_task').first&.value
    if profile == 1
      report = MemoryProfiler.report do
        block.call(run)
      end
      run.update!(
        memory_allocated: report.total_allocated_memsize,
        memory_retained: report.total_retained_memsize,
        allocation_count: report.total_allocated,
      )
    else
      block.call(run)
    end
  end

  protected

  def find_or_create_maintenance_task(name, alert_threshold:)
    minutes = alert_threshold.to_i / 60
    raise ArgumentError, "Alert threshold must be positive, got: #{alert_threshold}" unless minutes.positive?

    task = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(name: name).first_or_initialize
    task.completion_alert_minutes = minutes
    task.save! if task.changed?
    task
  end
end
