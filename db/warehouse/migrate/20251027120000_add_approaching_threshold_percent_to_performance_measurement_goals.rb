###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddApproachingThresholdPercentToPerformanceMeasurementGoals < ActiveRecord::Migration[7.1]
  def change
    add_column :performance_measurement_goals, :approaching_threshold_percent, :integer
  end
end
