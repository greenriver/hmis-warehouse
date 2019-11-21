class AddEdipVisitReport < ActiveRecord::Migration[4.2]
    REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/ed_ip_visits',
        name: 'ED & IP Visits',
        description: 'Upload and attach ED & IP visits to patient records.',
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
