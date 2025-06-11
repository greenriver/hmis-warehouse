# frozen_string_literal: true

class GrdaWarehouse::Tasks::SystemMaintenanceTaskRun < GrdaWarehouseBase
  self.table_name = 'system_maintenance_task_runs'

  belongs_to :system_maintenance_task, class_name: 'GrdaWarehouse::Tasks::SystemMaintenanceTask'

  scope :expired, -> {
    now = Time.current
    expiration_threshold = now - 6.months
    where(started_at: ..expiration_threshold)
  }

  def completed?
    completed_at.present?
  end

  def complete!
    transaction do
      update!(completed_at: Time.current)
      # if the run completed, clear alert_sent_at so it will trigger in the future
      system_maintenance_task.update!(alert_sent_at: nil)
    end
  end
end
