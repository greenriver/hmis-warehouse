class CorrectCapitalizationConflictingAttributes < ActiveRecord::Migration
  def up
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/conflicting_client_attributes').update_all(name: 'Clients with Conflicting Reported Attributes', description: 'Identify clients whose source record attributes differ between data sources.')
  end
end
