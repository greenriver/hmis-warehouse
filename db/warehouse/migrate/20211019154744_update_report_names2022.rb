class UpdateReportNames2022 < ActiveRecord::Migration[5.2]
  def up
    HudReports::ReportInstance.distinct.pluck(:report_name).each do |report_name|
      next unless report_name.include?('FY 2021')
      next if report_name.include?('LSA - FY')

      new_name = report_name.gsub('2021', '2022')
      HudReports::ReportInstance.where(report_name: report_name).update_all(report_name: new_name)
    end
  end
end
