class AddPremiumPaymentsReport < ActiveRecord::Migration
  UP_REPORTS = {
    'Health' => [
      {
        url: 'warehouse_reports/health/premium_payments',
        name: 'Process Premium Payments (820)',
        description: 'Convert 820 files into human-readable Excel files',
        limitable: false,
      },
    ],
  }

  # DOWN_REPORTS = {
  #   'Operational Reports' => [
  #     {
  #       url: 'warehouse_reports/youth_export',
  #       name: 'Youth Export',
  #       description: 'Download youth data',
  #       limitable: false,
  #     },
  #   ],
  # }


  def up
    UP_REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.create(
          report_group: group,
          url: report[:url],
          name: report[:name],
          description: report[:description],
          limitable: report[:limitable],
        )
      end
    end
    # DOWN_REPORTS.each do |group, reports|
    #   reports.each do |report|
    #     GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report[:url]).delete_all
    #   end
    # end
  end

  def down
    UP_REPORTS.each do |group, reports|
      reports.each do |report|
        GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report[:url]).delete_all
      end
    end
    # DOWN_REPORTS.each do |group, reports|
    #   reports.each do |report|
    #     GrdaWarehouse::WarehouseReports::ReportDefinition.create(
    #       report_group: group,
    #       url: report[:url],
    #       name: report[:name],
    #       description: report[:description],
    #       limitable: report[:limitable],
    #     )
    #   end
    # end
  end
end
