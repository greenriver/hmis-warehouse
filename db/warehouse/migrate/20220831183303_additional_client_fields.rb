class AdditionalClientFields < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_clients, :gender_none, :integer
    add_column :hmis_dqt_clients, :overlapping_entry_exit, :integer
    add_column :hmis_dqt_clients, :overlapping_nbn, :integer
    add_column :hmis_dqt_clients, :overlapping_pre_move_in, :integer
    add_column :hmis_dqt_clients, :overlapping_post_move_in, :integer
  end
end
