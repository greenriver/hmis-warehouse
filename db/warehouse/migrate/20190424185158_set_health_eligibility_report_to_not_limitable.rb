class SetHealthEligibilityReportToNotLimitable < ActiveRecord::Migration[4.2]
  def change
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/health/eligibility').update_all(limitable: false)
  end
end
