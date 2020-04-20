class AddProjectIdsToReportInstances < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_instances, :project_ids, :json
  end
end
