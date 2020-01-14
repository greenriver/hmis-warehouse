class SpellingFixForReport < ActiveRecord::Migration[4.2]
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.find_by(url: 'warehouse_reports/youth_export')&.update(description: 'Youth data for a given time frame.')
  end
end
