class AddIndexesToPdq < ActiveRecord::Migration[4.2]
  def change
    add_index :warehouse_data_quality_report_enrollments, [:report_id, :active, :entered, :head_of_household, :enrolled], name: :pdq_rep_act_ent_head_enr
    add_index :warehouse_data_quality_report_enrollments, [:report_id, :active, :exited, :head_of_household, :enrolled], name: :pdq_rep_act_ext_head_enr
    add_index :warehouse_data_quality_report_projects, [:report_id, :project_id], name: :pdq_projects_report_id_project_id
    add_index :warehouse_data_quality_report_project_groups, :report_id, name: :pdq_p_groups_report_id
  end
end
