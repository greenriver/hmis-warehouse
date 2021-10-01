class AdjustYouthEducationStatusIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :YouthEducationStatus, [:YouthEducationStatusID, :data_source_id]
    add_index :YouthEducationStatus, [:YouthEducationStatusID, :data_source_id], name: :youth_ed_ev_id_ds_id, unique: true
  end
end
