class SpellingFixForReport < ActiveRecord::Migration
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.find_by(url: 'warehouse_reports/youth_export').update(description: 'Youth data for a given time frame.')
  end
end
