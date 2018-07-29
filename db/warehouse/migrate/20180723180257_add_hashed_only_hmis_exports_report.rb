class AddHashedOnlyHmisExportsReport < ActiveRecord::Migration
    REPORTS = {
      'Operational Reports' => [
        {
          url: 'warehouse_reports/hashed_only_hmis_exports',
          name: 'HUD HMIS CSV Exports (Hashed Only)',
          description: 'Export data in the HUD HMIS exchange format with PII hashed',
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
