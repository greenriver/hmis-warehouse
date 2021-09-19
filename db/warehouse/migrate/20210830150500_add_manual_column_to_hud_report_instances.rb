class AddManualColumnToHudReportInstances < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_instances, :manual, :boolean, null: false, default: true
  end
end
