class AddEnrolledInProjectTypeReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/enrolled_project_type',
        name: 'Enrollments per project type',
        description: 'A list of clients who were enrolled in a set of project types for a given date range.',
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
