class AdjustDescriptionForOpenEnrollment < ActiveRecord::Migration
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(
      url: 'warehouse_reports/open_enrollments_no_service',
    ).update_all(description: 'Client enrollments that may need to be closed.')
  end
end
