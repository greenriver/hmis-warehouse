# frozen_string_literal: true

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
      profile_data = PeakMemorySampler.profile do
        block.call(run)
      end
      run.update!(memory_allocated: profile_data[:peak_memory_bytes])
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
