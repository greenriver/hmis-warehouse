class AddMissingIndexes20221028 < ActiveRecord::Migration[6.1]
  def change
    add_index :hud_report_universe_members, :report_cell_id, where: "deleted_at is null"
    add_index :hmis_dqt_enrollments, :project_id
  end
end
