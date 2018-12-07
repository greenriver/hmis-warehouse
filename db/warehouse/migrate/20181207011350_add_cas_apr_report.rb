class AddCasAprReport < ActiveRecord::Migration
  REPORTS = {
    'CAS' => [
      {
        url: 'warehouse_reports/cas/apr',
        name: 'CAS APR',
        description: 'High-level counts of CAS activity for a date range',
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
