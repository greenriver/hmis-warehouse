class MakeHudReportInstancesSti < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_instances, :type, :string, default: 'HudReports::ReportInstance', null: false
  end
end
