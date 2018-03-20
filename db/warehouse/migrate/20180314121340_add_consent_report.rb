class AddConsentReport < ActiveRecord::Migration
  REPORTS = {
    'CAS' => [
      {
        url: 'warehouse_reports/consent',
        name: 'Consent Processing',
        description: 'Review and process consent and disability forms for potentially CAS ready clients.',
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
