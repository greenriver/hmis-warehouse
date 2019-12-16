class RemoveHtmlFromHudChronicReportDescription < ActiveRecord::Migration[5.2]
  def change
    GrdaWarehouse::WarehouseReports::ReportDefinition.find_by(url: 'warehouse_reports/hud_chronics').
      update(description: "Clients who meet the HUD definition of Chronically Homeless as outlined in the HMIS Glossary.<br />Calculated using self-report data from entry assessments." )
  end
end
