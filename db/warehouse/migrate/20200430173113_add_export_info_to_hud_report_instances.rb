class AddExportInfoToHudReportInstances < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_instances, :question_names, :json, null: false
    add_column :hud_report_instances, :zip_file, :binary
  end
end
