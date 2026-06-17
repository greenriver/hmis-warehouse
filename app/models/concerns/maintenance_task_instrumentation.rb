###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides instrumentation for maintenance tasks to track execution and alert on failures
module MaintenanceTaskInstrumentation
  extend ActiveSupport::Concern

  protected

  def instrument_as_maintenance_task(name: nil, alert_threshold: 36.hours, &block)
    if name.present?
      # prefix the with the current class name
      name = "#{self.class.name}: #{name}"
    else
      # no name provided, default to the name of the calling method
      caller_name = caller_locations(1, 1)[0].label # skip 1 frame to get the actual calling method
      name = "#{self.class.name}##{caller_name}"
    end
    GrdaWarehouse::Tasks::TaskInstrumentation.call(name, alert_threshold: alert_threshold, &block)
  end
end
