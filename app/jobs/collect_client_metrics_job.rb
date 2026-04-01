###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CollectClientMetricsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority MAINTENANCE_PRIORITY_15

  REQUEUE_WAIT_MINUTES = 5
  RETRY_DEADLINE_HOUR = 10 # Don't retry after 10 AM — avoids infinite loops on persistent instability, gives it roughly 8 hours to stabilize

  def perform(calculation_date = Date.current, metric_names: nil)
    GrdaWarehouseBase.with_advisory_lock('collect_client_metrics_job', timeout_seconds: 0) do
      skipped_metric_names = GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector.run_daily_collection(
        entity_type: 'GrdaWarehouse::Hud::Client',
        calculation_date: calculation_date,
        metric_names: metric_names,
      )

      schedule_retry(calculation_date, skipped_metric_names) if skipped_metric_names.any?
    end
  end

  private

  def schedule_retry(calculation_date, skipped_metric_names)
    if Time.current.hour >= RETRY_DEADLINE_HOUR
      Rails.logger.warn(
        "#{self.class.name}: past retry deadline (#{RETRY_DEADLINE_HOUR}:00), " \
        "giving up on #{skipped_metric_names.join(', ')} for #{calculation_date}",
      )
      return
    end

    Rails.logger.info(
      "#{self.class.name}: requeueing #{skipped_metric_names.join(', ')} " \
      "in #{REQUEUE_WAIT_MINUTES} minutes for #{calculation_date}",
    )
    self.class.set(wait: REQUEUE_WAIT_MINUTES.minutes).perform_later(
      calculation_date,
      metric_names: skipped_metric_names,
    )
  end
end
