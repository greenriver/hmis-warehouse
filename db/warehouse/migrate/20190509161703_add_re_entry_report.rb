class AddReEntryReport < ActiveRecord::Migration
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/re_entry',
        name: 'Homelessness Re-Entry',
        description: 'Details on clients who returned to homelessness after a 60 day break',
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
