# frozen_string_literal: true

class GrdaWarehouse::Tasks::SystemMaintenanceTaskRun < GrdaWarehouseBase
  self.table_name = 'system_maintenance_tasks_run'

  belongs_to :system_maintenance_task, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTask'
end
