class AddLastPermanentZipReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/client_details/last_permanent_zips',
        name: 'Last Permanent Zip Report',
        description: 'List open enrollments within a date range and the zip codes of last permanent residence.',
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

