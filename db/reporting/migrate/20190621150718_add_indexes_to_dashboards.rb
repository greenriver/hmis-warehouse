class AddIndexesToDashboards < ActiveRecord::Migration
  def change
    remove_index :warehouse_monthly_reports, column: [:type, :month, :year, :project_type], name: 'idx_monthly_rep_on_type_and_month_and_year_and_p_type'
    add_index :warehouse_monthly_reports, [:type, :destination_id, :enrolled], name: :idx_dest_type_enr
    add_index :warehouse_monthly_reports, [:type, :month, :year, :project_type, :enrolled], name: :idx_year_month_type_proj_enr
    add_index :warehouse_monthly_reports, [:type, :month, :year, :project_type, :active, :entered, :head_of_household], name: :idx_year_month_type_proj_act_ent
    add_index :warehouse_monthly_reports, [:type, :month, :year, :project_type, :active, :exited, :head_of_household], name: :idx_year_month_type_proj_act_ext
    add_index :warehouse_monthly_reports, [:type, :month, :year, :project_type, :head_of_household], name: :idx_year_month_type_proj_head
    add_index :warehouse_monthly_reports, [:type, :month, :year, :enrolled], name: :idx_year_month_type_enr
    add_index :warehouse_monthly_reports, [:type, :month, :year, :active, :entered, :head_of_household], name: :idx_year_month_type_act_ent
    add_index :warehouse_monthly_reports, [:type, :month, :year, :active, :exited, :head_of_household], name: :idx_year_month_type_act_ext
    add_index :warehouse_monthly_reports, [:type, :month, :year, :head_of_household], name: :idx_year_month_type_head
  end
end
