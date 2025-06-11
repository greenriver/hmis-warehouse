# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Provides instrumentation for maintenance tasks to track execution and alert on failures
module MaintenanceTaskInstrumentation
  extend ActiveSupport::Concern

  protected

  def instrument_as_maintenance_task(name, alert_threshold: 36.hours, &block)
    qualified_name = "#{self.class.name}:#{name}"
    GrdaWarehouse::Tasks::TaskInstrumentation.call(qualified_name, alert_threshold: alert_threshold, &block)
  end
end
