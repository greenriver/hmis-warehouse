# frozen_string_literal: true

# Tracks maintenance tasks and their execution history for monitoring and alerting.
# Each task represents a recurring maintenance operation (like data cleanup, imports, etc.)
# and maintains a history of execution runs to detect when tasks fail or don't complete on schedule.
#
class GrdaWarehouse::Tasks::SystemMaintenanceTask < GrdaWarehouseBase
  self.table_name = 'system_maintenance_tasks'

  has_many :system_maintenance_task_runs, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTaskRun'

  # TODO: Add support for monitoring task runtime duration to alert when tasks run too long
  # This would need an additional threshold value and a calculation based on
  # the difference between started_at and completed_at timestamps

  def last_completed_at
    system_maintenance_task_runs.maximum(:completed_at)
  end

  def average_run_time
    # average last 5 runs
    system_maintenance_task_runs.order(id: :desc).completed.limit(5).average_run_time
  end

  # Checks if the task has exceeded its completion threshold
  # @param now [Time] current time for threshold calculation
  # @return [Boolean] true if no successful completions within the threshold period
  def threshold_exceeded?(now: Time.current)
    return false unless completion_alert_minutes&.positive?

    # have we completed tasks within the threshold?
    threshold = now - completion_alert_minutes.minutes
    system_maintenance_task_runs.where(completed_at: threshold...).none?
  end

  # Processes and sends alerts for tasks that have exceeded their thresholds
  # Only sends one alert per threshold breach to avoid chatter
  def process_alerts(now: Time.current)
    return unless should_send_alert?(now)

    alerts = []
    alerts << "Missing scheduled execution: Task has not completed successfully in the last #{completion_alert_minutes} minutes" if threshold_exceeded?(now: now)
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
