class PerformanceIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :Disabilities, [:EnrollmentID, :PersonalID, :DateDeleted, :data_source_id], name: 'idx_dis_p_id_e_id_del_ds_id', where: '"IndefiniteAndImpairs" = 1;'
  end
end
