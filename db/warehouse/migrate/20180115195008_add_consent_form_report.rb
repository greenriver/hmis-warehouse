class AddConsentFormReport < ActiveRecord::Migration
  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/expiring_consent',
        name: 'Expiring Consent',
        description: 'Clients whose consent form has expired or expires soon.'
      },
    ],
  }


  def up
    REPORTS.each do |group, reports|
      reports.each do |report|
        puts "Creating report: #{report[:name]}"
        GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
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
