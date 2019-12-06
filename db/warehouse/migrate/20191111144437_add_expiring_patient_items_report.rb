class AddExpiringPatientItemsReport < ActiveRecord::Migration
  REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/expiring_items',
        name: 'Expiring Items',
        description: 'See who has Participation Forms, Release Forms, SSMs, CHAs, and PCTPs that are expiring or expired.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/health/ssm_exports',
        name: 'Self-Sufficiency Matrix Form Export',
        description: 'Export SSMs from any source, ETO, EPIC, and the Warehouse.',
        limitable: true,
      }
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
