class AddHealthEnrollmentReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/enrollments',
        name: 'Health Care Enrollments (834)',
        description: 'Update patient enrollments.',
        limitable: false,
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
