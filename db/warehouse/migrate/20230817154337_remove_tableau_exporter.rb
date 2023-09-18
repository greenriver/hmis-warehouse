class RemoveTableauExporter < ActiveRecord::Migration[6.1]
  def up
    url = 'warehouse_reports/tableau_dashboard_export'
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).update_all(deleted_at: Time.current)
  end
end
