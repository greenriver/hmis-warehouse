class AdditionalWarehouseReportPermissions < ActiveRecord::Migration

  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/veteran_details/actives',
        name: 'Active Veteran Detail',
        description: 'Veterans with service within a date range.'
      },
      {
        url: 'warehouse_reports/veteran_details/entries',
        name: 'Veteran Entry Detail',
        description: 'Veterans with entries into a project type within a date range.'
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
