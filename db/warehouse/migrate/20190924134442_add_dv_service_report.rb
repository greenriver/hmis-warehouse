class AddDvServiceReport < ActiveRecord::Migration
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/dv_victim_service',
        name: 'DV Victim Service Report',
        description: 'Clients fleeing domestic violence.',
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
