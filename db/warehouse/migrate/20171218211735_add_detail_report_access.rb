class AddDetailReportAccess < ActiveRecord::Migration

  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/client_details/actives',
        name: 'Active Client Detail',
        description: 'Clients with service within a date range.'
      },
      {
        url: 'warehouse_reports/client_details/entries',
        name: 'Client Entry Detail',
        description: 'Clients with entries into a project type within a date range.'
      },
      {
        url: 'warehouse_reports/client_details/exits',
        name: 'Client Exit Detail',
        description: 'Clients with entries into a project type within a date range.'
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

    [
      'warehouse_reports/veteran_details/actives',
      'warehouse_reports/veteran_details/entries',
      'warehouse_reports/veteran_details/exits',
    ].each do |url|
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).delete_all
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
