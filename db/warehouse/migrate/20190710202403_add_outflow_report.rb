class AddOutflowReport < ActiveRecord::Migration
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/outflow',
        name: 'Client Outflow',
        description: 'Clients who exited homelessness, or who have no recent homeless service.',
        limitable: true,
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
          description: report[:description],
          limitable: report[:limitable]
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
