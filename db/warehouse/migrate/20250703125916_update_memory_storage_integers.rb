###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UpdateMemoryStorageIntegers < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_column :system_maintenance_task_runs, :memory_allocated, :bigint
      change_column :system_maintenance_task_runs, :memory_retained, :bigint
    end
  end
end
