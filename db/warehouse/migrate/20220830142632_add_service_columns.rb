class AddServiceColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_services, :entry_date, :date
    add_column :hmis_dqt_services, :exit_date, :date
    add_column :hmis_dqt_services, :project_type, :integer
    add_column :hmis_dqt_services, :overlapping_entry_exit, :integer
    add_column :hmis_dqt_services, :overlapping_nbn, :integer
    add_column :hmis_dqt_services, :overlapping_pre_move_in, :integer
    add_column :hmis_dqt_services, :overlapping_post_move_in, :integer
  end
end
