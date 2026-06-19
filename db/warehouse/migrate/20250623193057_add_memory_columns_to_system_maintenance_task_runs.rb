###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddMemoryColumnsToSystemMaintenanceTaskRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :system_maintenance_task_runs, :memory_allocated, :integer
    add_column :system_maintenance_task_runs, :memory_retained, :integer
    add_column :system_maintenance_task_runs, :allocation_count, :integer
  end
end
