class AddOverlapDetailsToHmisDqEnrollments < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_dqt_clients, :overlapping_entry_exit_details, :jsonb
    add_column :hmis_dqt_clients, :overlapping_nbn_details, :jsonb
    add_column :hmis_dqt_clients, :overlapping_pre_move_in_details, :jsonb
    add_column :hmis_dqt_clients, :overlapping_post_move_in_details, :jsonb
  end
end
