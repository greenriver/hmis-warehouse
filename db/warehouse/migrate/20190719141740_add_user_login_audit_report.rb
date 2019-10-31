class AddUserLoginAuditReport < ActiveRecord::Migration[4.2]
  REPORTS = {
    'Audit Reports' => [
      {
        url: 'audit_reports/user_login',
        name: 'User Login Report',
        description: 'Report most recent logins by users',
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
