# frozen_string_literal: true

require 'memory_profiler'
class GrdaWarehouse::Tasks::TaskInstrumentation
  include Singleton

  # convenience method
  def self.call(...) = instance.call(...)

  def call(name, alert_threshold:, &block)
    task = find_or_create_maintenance_task(name, alert_threshold: alert_threshold)
    run = task.system_maintenance_task_runs.create!(started_at: Time.current)
    if Rails.env.production?
      block.call(run)
    else
      report = MemoryProfiler.report do
        block.call(run)
      end
      run.update!(
        memory_allocated_mb: report.total_allocated_memsize / 1024 / 1024,
        memory_retained_mb: report.total_retained_memsize / 1024 / 1024,
        allocation_count: report.total_allocated,
      )
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
