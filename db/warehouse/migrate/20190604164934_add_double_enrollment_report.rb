class AddDoubleEnrollmentReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Data Quality' => [
      {
        url: 'warehouse_reports/double_enrollments',
        name: 'Doubly Enrolled Clients',
        description: 'Clients enrolled in multiple simultaneous projects of the same type.',
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
