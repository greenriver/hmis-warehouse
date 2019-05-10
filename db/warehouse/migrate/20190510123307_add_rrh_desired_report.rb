class AddRrhDesiredReport < ActiveRecord::Migration
  REPORTS = {
    'CAS' => [
      {
        url: 'warehouse_reports/cas/rrh_desired',
        name: 'Clients Interested in RRH',
        description: 'Who has indicated interest in RRH but does not yet have any consent on file',
        limitable: false,
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
