###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CollectClientMetricsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)
  queue_with_priority 10

  def perform(calculation_date = Date.current)
    GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector.run_daily_collection(
      entity_type: 'GrdaWarehouse::Hud::Client',
      calculation_date: calculation_date,
    )
  end

  def priority
    15
  end
end
