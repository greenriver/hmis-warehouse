# frozen_string_literal: true

class GrdaWarehouse::Tasks::SystemMaintenanceTask < GrdaWarehouseBase
  self.table_name = 'system_maintenance_tasks'

  has_many :system_maintenance_task_runs, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTaskRun'

  def call
    run = system_maintenance_task_runs.create!(started_at: Time.current)
    yield
    run.update!(completed_at: Time.current)
  end

  def threshold_exceeded?(now: Time.current)
    return false unless alert_threshold_minutes&.positive?

    # have we completed tasks within the threshold?
    threshold = now - alert_threshold_minutes.minutes
    system_maintenance_task_runs.where(completed_at: threshold...).none?
  end

  def process_alerts(now: Time.current)
    return unless should_send_alert?(now)

    alerts = []
    alerts << "Exceeded threshold, task has not completed in #{alert_threshold_minutes} minutes" if threshold_exceeded?(now: now)
    return if alerts.empty?

    tag = "#{self.class.name.demodulize}# \"#{name}\""
    alerts.each { |m| Sentry.capture_message("#{tag}: #{m}") }
    update!(alert_sent_at: now)
  end

  private

  def should_send_alert?(now)
    # Only send alert once
    return false if alert_sent_at
    return false unless threshold_exceeded?(now: now)

    # we could debounce by checking alert_sent if it becomes too noisy
    true
  end
end
