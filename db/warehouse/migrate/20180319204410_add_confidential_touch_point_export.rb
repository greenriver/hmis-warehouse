class AddConfidentialTouchPointExport < ActiveRecord::Migration
  REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/overview',
        name: 'Health Dashboard',
        description: 'Overview of patient metrics.',
      },
      {
        url: 'warehouse_reports/confidential_touch_point_exports',
        name: 'Health-related TouchPoint Export',
        description: 'Export for any Confidential Health-related TouchPoints.',
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
