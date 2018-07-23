class AddHashedOnlyHmisExportsReport < ActiveRecord::Migration
    REPORTS = {
      'Operational Reports' => [
        {
          url: 'warehouse_reports/hashed_only_hmis_exports',
          name: 'Hashed Only HMIS Exports',
          description: 'Hashed only HMIS exports',
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
