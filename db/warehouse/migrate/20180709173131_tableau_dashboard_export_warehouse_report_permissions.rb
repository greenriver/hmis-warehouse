class TableauDashboardExportWarehouseReportPermissions < ActiveRecord::Migration
    REPORTS = {
      'Operational Reports' => [
        {
          url: 'warehouse_reports/tableau_dashboard_export',
          name: 'Tableau Dashboard Export',
          description: 'Download dashboard data sets.'
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
