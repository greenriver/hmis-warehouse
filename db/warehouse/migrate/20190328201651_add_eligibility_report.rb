class AddEligibilityReport < ActiveRecord::Migration
  REPORTS = {
      'Health' => [
          {
              url: 'warehouse_reports/health/eligibility',
              name: 'Eligibility Determination',
              description: 'Generate and download eligibility determination files.',
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
