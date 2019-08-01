class AddConflictingClientAttributesReport < ActiveRecord::Migration
  REPORTS = {
    'Data Quality' => [
      {
        url: 'warehouse_reports/conflicting_client_attributes',
        name: 'Clients With Conflicting Reported Attributes',
        description: 'Clients with different attributes in data sources.'
      },
    ],
  }


  def up
    REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.create(
          report_group: group,
          url: report[:url],
          name: report[:name],
          description: report[:description]
        )
      end
    end
  end

  def down
    REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report[:url]).delete_all
      end
    end
  end
end
