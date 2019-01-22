class AddCasVacanciesReport < ActiveRecord::Migration
  REPORTS = {
      'CAS' => [
          {
              url: 'warehouse_reports/cas/vacancies',
              name: 'CAS Vacancies',
              description: 'CAS vacancies for a given date range',
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
