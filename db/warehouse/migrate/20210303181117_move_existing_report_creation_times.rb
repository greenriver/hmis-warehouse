class MoveExistingReportCreationTimes < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.update_all(created_at: 1.months.ago)
  end
end
