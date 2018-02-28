class AddTouchPointExportReport < ActiveRecord::Migration
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/touch_point_exports',
        name: 'Export Touch Points',
        description: 'Export CSVs of ETO TouchPoints.',
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
