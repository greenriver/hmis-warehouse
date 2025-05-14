# frozen_string_literal: true

class GrdaWarehouse::Tasks::SystemMaintenanceTask < GrdaWarehouseBase
  self.table_name = 'system_maintenance_tasks'

  has_many :system_maintenance_task_runs, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTaskRuns'

  def self.call
    run = system_maintenance_task_runs.create!(started_at: Time.current)
    begin
      yield
    ensure
      run.update!(completed_at: Time.current)
    end
  end

  def threshold_exceeded?(now: Time.current)
    return unless alert_threshold_minutes.minutes

    # have we completed tasks within the threshold?
    threshold = now - alert_threshold_minutes.minutes
    system_maintenance_task_runs.where(completed_at: threshold...).exists?
  end

  def process_alerts(now: Time.current)
    alerts = []
    alerts << "Exceeded threshold, task has not completed in #{alert_threshold_minutes} minutes" if threshold_exceeded?
    return if alerts.empty?

    tag = "#{self.class.demodulize}# \"#{name}\""
    alerts.each { |m| Sentry.capture_message("#{tag}: #{m}") }
    update!(alert_sent_at: now)
  end
end
