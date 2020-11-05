class MoveHudReportCoCCode < ActiveRecord::Migration[5.2]
  def change
    HudReports::ReportInstance.find_each do |i|
      i.update(coc_codes: [i.coc_code])
    end
  end
end
