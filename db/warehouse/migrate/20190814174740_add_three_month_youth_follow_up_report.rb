class AddThreeMonthYouthFollowUpReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/youth_follow_ups',
        name: 'Homeless Youth Follow Up Report',
        description: 'Youth who require a three month follow up',
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
