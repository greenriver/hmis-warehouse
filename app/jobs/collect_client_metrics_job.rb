###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CollectClientMetricsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority 15

  def perform(calculation_date = Date.current)
    lock_name = 'collect_client_metrics_job'
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
      GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector.run_daily_collection(
        entity_type: 'GrdaWarehouse::Hud::Client',
        calculation_date: calculation_date,
      )
    end
  end

  def priority
    15
  end
end
