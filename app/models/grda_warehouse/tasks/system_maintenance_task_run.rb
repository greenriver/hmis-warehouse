# frozen_string_literal: true

class GrdaWarehouse::Tasks::SystemMaintenanceTaskRun < GrdaWarehouseBase
  self.table_name = 'system_maintenance_task_runs'

  belongs_to :system_maintenance_task, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTask'

  scope :expired, -> {
    now = Time.current
    expiration_threshold = now - 6.months
    where(started_at: ..expiration_threshold)
  }
end
